import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Dịch vụ Geocoding dùng Nominatim (OpenStreetMap) — hoàn toàn miễn phí
class GeocodingService {
  static const int _candidateLimit = 6;
  static const Duration _negativeCacheTtl = Duration(minutes: 12);
  static const double _minVnScore = 1.2;
  static const double _minGlobalScore = 0.9;
  static const double _minVnOverlap = 0.20;
  static const double _minGlobalOverlap = 0.16;

  /// Cache kết quả geocode thành công
  final Map<String, LatLng> _successCache = {};

  /// Negative cache có TTL để tránh spam request khi địa điểm vừa fail
  final Map<String, DateTime> _negativeCache = {};

  /// Chuyển tên địa điểm → toạ độ LatLng
  /// Trả về `null` nếu không tìm thấy
  Future<LatLng?> geocode(String locationText) async {
    final query = _normalizeQuery(locationText);
    if (query.isEmpty) return null;

    final cached = _successCache[query];
    if (cached != null) return cached;

    if (_isNegativeCached(query)) {
      return null;
    }

    try {
      final variants = _buildQueryVariants(query);

      // Pass 1: ưu tiên Việt Nam.
      for (final variant in variants) {
        final vnCandidates = await _requestCandidates(
          variant,
          countryCode: 'vn',
        );
        final best = _pickBestCandidate(
          vnCandidates,
          variant,
          preferVietnam: true,
        );
        if (best != null) {
          _successCache[query] = best.point;
          _negativeCache.remove(query);
          return best.point;
        }
      }

      // Pass 2: fallback toàn cầu.
      for (final variant in variants) {
        final globalCandidates = await _requestCandidates(variant);
        final best = _pickBestCandidate(
          globalCandidates,
          variant,
          preferVietnam: false,
        );
        if (best != null) {
          _successCache[query] = best.point;
          _negativeCache.remove(query);
          return best.point;
        }
      }

      _negativeCache[query] = DateTime.now();
      debugPrint('ℹ️ Geocoding unresolved "$query"');
      return null;
    } catch (e) {
      debugPrint('⚠️ Geocoding error for "$query": $e');
      _negativeCache[query] = DateTime.now();
      return null;
    }
  }

  /// Geocode nhiều địa điểm cùng lúc (tuần tự, tôn trọng rate limit Nominatim)
  Future<Map<String, LatLng>> geocodeAll(List<String> locations) async {
    final results = <String, LatLng>{};

    for (final loc in locations.toSet()) {
      // Nominatim yêu cầu max 1 req/giây
      final point = await geocode(loc);
      if (point != null) {
        results[loc] = point;
      }
      // Delay 1.1s giữa mỗi request để tôn trọng rate limit
      await Future.delayed(const Duration(milliseconds: 1100));
    }

    return results;
  }

  String _normalizeQuery(String raw) {
    var normalized = raw.toLowerCase().trim();

    // Loại bỏ ký tự dễ gây nhiễu khi người dùng nhập thêm ghi chú/emoji.
    normalized = normalized.replaceAll(RegExp(r'[\(\)\[\]\{\}]'), ' ');
    normalized = normalized.replaceAll(RegExp(r'[-_/|]+'), ' ');
    normalized = normalized.replaceAll(RegExp(r'[.,;:]+'), ' ');
    normalized = normalized.replaceAll(RegExp(r'[^0-9a-zà-ỹ\s]'), ' ');

    normalized = _expandVietnameseAbbreviations(normalized);
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    return normalized;
  }

  String _expandVietnameseAbbreviations(String value) {
    var s = value;
    final replacements = <MapEntry<RegExp, String>>[
      MapEntry(RegExp(r'\btp\s*hcm\b'), 'thanh pho ho chi minh'),
      MapEntry(RegExp(r'\btp\s*hn\b'), 'thanh pho ha noi'),
      MapEntry(RegExp(r'\btp\b'), 'thanh pho'),
      MapEntry(RegExp(r'\bq\b'), 'quan'),
      MapEntry(RegExp(r'\bp\b'), 'phuong'),
      MapEntry(RegExp(r'\bh\b'), 'huyen'),
      MapEntry(RegExp(r'\btx\b'), 'thi xa'),
      MapEntry(RegExp(r'\btt\b'), 'thi tran'),
      MapEntry(RegExp(r'\bvn\b'), 'viet nam'),
    ];

    for (final entry in replacements) {
      s = s.replaceAll(entry.key, entry.value);
    }

    return s;
  }

  List<String> _buildQueryVariants(String normalized) {
    final variants = <String>{normalized};
    final withCountry = _ensureVietnamSuffix(normalized);
    variants.add(withCountry);

    final compact = normalized
        .replaceAll(
          RegExp(r'\b(viet nam|thanh pho|quan|phuong|huyen|thi xa|thi tran)\b'),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (compact.isNotEmpty) {
      variants.add(compact);
      variants.add(_ensureVietnamSuffix(compact));
    }

    return variants.where((v) => v.isNotEmpty).toList();
  }

  String _ensureVietnamSuffix(String query) {
    if (query.contains('viet nam') || query.contains('vietnam')) return query;
    return '$query viet nam';
  }

  bool _isNegativeCached(String query) {
    final failedAt = _negativeCache[query];
    if (failedAt == null) return false;

    final stillFresh = DateTime.now().difference(failedAt) < _negativeCacheTtl;
    if (!stillFresh) {
      _negativeCache.remove(query);
    }

    return stillFresh;
  }

  Future<List<_GeocodeCandidate>> _requestCandidates(
    String query, {
    String? countryCode,
  }) async {
    final countryParam =
        countryCode != null ? '&countrycodes=${Uri.encodeComponent(countryCode)}' : '';

    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(query)}'
      '&format=json'
      '&addressdetails=1'
      '&limit=$_candidateLimit'
      '$countryParam',
    );

    final response = await http.get(
      uri,
      headers: {'User-Agent': 'DuXuanApp/1.0'},
    );

    if (response.statusCode != 200) {
      debugPrint(
        '⚠️ Geocoding status ${response.statusCode} for "$query"'
        '${countryCode != null ? ' (country=$countryCode)' : ''}',
      );
      return [];
    }

    final body = json.decode(response.body);
    if (body is! List) return [];

    final candidates = <_GeocodeCandidate>[];
    for (final item in body) {
      if (item is! Map) continue;

      final map = Map<String, dynamic>.from(item);
      final lat = double.tryParse(map['lat']?.toString() ?? '');
      final lon = double.tryParse(map['lon']?.toString() ?? '');
      if (lat == null || lon == null) continue;

      final address = map['address'];
      var candidateCountry = '';
      if (address is Map) {
        candidateCountry =
            (address['country_code']?.toString() ?? '').toLowerCase();
      }

      final displayName = map['display_name']?.toString() ?? '';
      if (candidateCountry.isEmpty) {
        final lowered = displayName.toLowerCase();
        if (lowered.contains('viet nam') || lowered.contains('vietnam')) {
          candidateCountry = 'vn';
        }
      }

      final importance =
          double.tryParse(map['importance']?.toString() ?? '') ?? 0;

      candidates.add(_GeocodeCandidate(
        point: LatLng(lat, lon),
        displayName: displayName,
        countryCode: candidateCountry,
        importance: importance,
      ));
    }

    return candidates;
  }

  _GeocodeCandidate? _pickBestCandidate(
    List<_GeocodeCandidate> candidates,
    String query, {
    required bool preferVietnam,
  }) {
    if (candidates.isEmpty) return null;

    _GeocodeCandidate? bestCandidate;
    double bestScore = double.negativeInfinity;
    double bestOverlap = 0;

    for (final candidate in candidates) {
      final overlap = _tokenOverlapScore(query, candidate.displayName);
      final score = _candidateScore(
        candidate,
        overlap,
        preferVietnam: preferVietnam,
      );

      if (score > bestScore) {
        bestScore = score;
        bestOverlap = overlap;
        bestCandidate = candidate;
      }
    }

    if (bestCandidate == null) return null;

    final minScore = preferVietnam ? _minVnScore : _minGlobalScore;
    final minOverlap = preferVietnam ? _minVnOverlap : _minGlobalOverlap;
    if (bestScore < minScore || bestOverlap < minOverlap) {
      debugPrint(
        'ℹ️ Geocoding low-confidence "$query": '
        'score=${bestScore.toStringAsFixed(2)}, '
        'overlap=${bestOverlap.toStringAsFixed(2)}',
      );
      return null;
    }

    return bestCandidate;
  }

  double _candidateScore(
    _GeocodeCandidate candidate,
    double overlap, {
    required bool preferVietnam,
  }) {
    var score = 0.0;

    if (candidate.countryCode == 'vn') {
      score += 2.5;
    } else if (preferVietnam) {
      score -= 1.5;
    }

    score += overlap * 3.0;
    score += candidate.importance * 1.2;

    return score;
  }

  double _tokenOverlapScore(String left, String right) {
    final leftTokens = _tokenize(left);
    if (leftTokens.isEmpty) return 0;
    final rightTokens = _tokenize(right);
    if (rightTokens.isEmpty) return 0;

    var intersection = 0;
    for (final token in leftTokens) {
      if (rightTokens.contains(token)) intersection++;
    }

    return intersection / leftTokens.length;
  }

  Set<String> _tokenize(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^0-9a-zà-ỹ\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.isEmpty) return {};

    return normalized
        .split(' ')
        .where((token) => token.length >= 2)
        .toSet();
  }
}

class _GeocodeCandidate {
  final LatLng point;
  final String displayName;
  final String countryCode;
  final double importance;

  const _GeocodeCandidate({
    required this.point,
    required this.displayName,
    required this.countryCode,
    required this.importance,
  });
}
