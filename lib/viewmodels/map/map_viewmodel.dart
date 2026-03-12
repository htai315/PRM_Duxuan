import 'package:flutter/material.dart';
import 'package:du_xuan/data/implementations/api/geocoding_service.dart';
import 'package:du_xuan/data/interfaces/repositories/i_activity_repository.dart';
import 'package:du_xuan/data/interfaces/repositories/i_plan_repository.dart';
import 'package:du_xuan/domain/entities/map_marker_data.dart';
import 'package:latlong2/latlong.dart';

class MapViewModel extends ChangeNotifier {
  static const double _sameLocationRadiusMeters = 35;
  static final Distance _distance = const Distance();

  final IPlanRepository _planRepo;
  final IActivityRepository _activityRepo;
  final GeocodingService _geocodingService;

  MapViewModel({
    required IPlanRepository planRepo,
    required IActivityRepository activityRepo,
    required GeocodingService geocodingService,
  })  : _planRepo = planRepo,
        _activityRepo = activityRepo,
        _geocodingService = geocodingService;

  // ─── State ────────────────────────────────────────────
  List<MapMarkerData> _markers = [];
  List<String> _unresolvedLocations = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Getters ──────────────────────────────────────────
  List<MapMarkerData> get markers => _markers;
  List<String> get unresolvedLocations => _unresolvedLocations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ─── Actions ──────────────────────────────────────────

  /// Load tất cả địa điểm từ mọi kế hoạch của user → geocode → markers
  Future<void> loadMarkers(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    _unresolvedLocations = [];
    notifyListeners();

    try {
      final plans = await _planRepo.getMyPlans(userId);
      final mergedGroups = <_MarkerGroup>[];
      final unresolvedSet = <String>{};

      // Thu thập locationText unique theo key chuẩn hoá trong từng plan.
      final locationBuckets = <String, _LocationBucket>{};

      for (final plan in plans) {
        // Load full plan with days
        final fullPlan = await _planRepo.getById(plan.id);
        if (fullPlan == null) continue;

        for (final day in fullPlan.days) {
          final activities = await _activityRepo.getByPlanDayId(day.id);
          for (final activity in activities) {
            final rawLoc = activity.locationText?.trim();
            if (rawLoc != null && rawLoc.isNotEmpty) {
              final normalized = _normalizeLocation(rawLoc);
              final key = '${fullPlan.id}::$normalized';
              final bucket = locationBuckets.putIfAbsent(
                key,
                () => _LocationBucket(
                  planId: fullPlan.id,
                  planName: fullPlan.name,
                  displayLocation: rawLoc,
                ),
              );

              bucket.absorbLocationVariant(rawLoc);
              bucket.activities.add(_ActivityInfo(title: activity.title));
            }
          }
        }
      }

      // Geocode từng địa điểm unique
      for (final bucket in locationBuckets.values) {
        final point = await _geocodingService.geocode(bucket.displayLocation);
        if (point != null) {
          _mergeResolvedBucket(mergedGroups, bucket, point);
        } else {
          unresolvedSet.add(bucket.displayLocation);
        }

        // Delay giữa mỗi geocode request (Nominatim rate limit)
        await Future.delayed(const Duration(milliseconds: 1100));
      }

      _markers = mergedGroups.map(_toMapMarker).toList();
      _unresolvedLocations = unresolvedSet.toList()..sort();
    } catch (e) {
      _errorMessage = 'Không thể tải dữ liệu bản đồ';
      debugPrint('❌ MapViewModel error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  String _normalizeLocation(String location) {
    return location
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[.,;:]+'), ' ')
        .replaceAll(RegExp(r'[-_/|]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  void _mergeResolvedBucket(
    List<_MarkerGroup> groups,
    _LocationBucket bucket,
    LatLng point,
  ) {
    for (final group in groups) {
      if (group.planId != bucket.planId) continue;

      final meters = _distance.as(
        LengthUnit.Meter,
        LatLng(group.lat, group.lng),
        point,
      );

      if (meters <= _sameLocationRadiusMeters) {
        group.merge(bucket, point);
        return;
      }
    }

    groups.add(_MarkerGroup.fromBucket(bucket, point));
  }

  MapMarkerData _toMapMarker(_MarkerGroup group) {
    final activityCount = group.activities.length;
    final title = activityCount == 1
        ? group.activities.first.title
        : '$activityCount hoạt động cùng địa điểm';

    return MapMarkerData(
      title: title,
      location: group.displayLocation,
      planName: group.planName,
      planId: group.planId,
      lat: group.lat,
      lng: group.lng,
    );
  }
}

/// Helper class nội bộ
class _ActivityInfo {
  final String title;

  const _ActivityInfo({
    required this.title,
  });
}

class _LocationBucket {
  final int planId;
  final String planName;
  String displayLocation;
  final List<_ActivityInfo> activities = [];

  _LocationBucket({
    required this.planId,
    required this.planName,
    required this.displayLocation,
  });

  void absorbLocationVariant(String candidate) {
    final currentScore = _detailScore(displayLocation);
    final candidateScore = _detailScore(candidate);
    if (candidateScore > currentScore) {
      displayLocation = candidate.trim();
    }
  }

  int _detailScore(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 0;
    final tokenCount = normalized.split(RegExp(r'\s+')).length;
    final commaBonus = ','.allMatches(normalized).length * 3;
    return normalized.length + tokenCount * 2 + commaBonus;
  }
}

class _MarkerGroup {
  final int planId;
  final String planName;
  String displayLocation;
  double lat;
  double lng;
  final List<_ActivityInfo> activities;

  _MarkerGroup({
    required this.planId,
    required this.planName,
    required this.displayLocation,
    required this.lat,
    required this.lng,
    required this.activities,
  });

  factory _MarkerGroup.fromBucket(_LocationBucket bucket, LatLng point) {
    return _MarkerGroup(
      planId: bucket.planId,
      planName: bucket.planName,
      displayLocation: bucket.displayLocation,
      lat: point.latitude,
      lng: point.longitude,
      activities: [...bucket.activities],
    );
  }

  void merge(_LocationBucket bucket, LatLng point) {
    final currentCount = activities.length;
    final addedCount = bucket.activities.length;
    final totalCount = currentCount + addedCount;

    lat = ((lat * currentCount) + (point.latitude * addedCount)) / totalCount;
    lng = ((lng * currentCount) + (point.longitude * addedCount)) / totalCount;

    if (_isMoreDetailed(bucket.displayLocation, displayLocation)) {
      displayLocation = bucket.displayLocation;
    }

    activities.addAll(bucket.activities);
  }

  bool _isMoreDetailed(String left, String right) {
    int score(String s) {
      final normalized = s.trim();
      if (normalized.isEmpty) return 0;
      final tokenCount = normalized.split(RegExp(r'\s+')).length;
      final commaBonus = ','.allMatches(normalized).length * 3;
      return normalized.length + tokenCount * 2 + commaBonus;
    }

    return score(left) > score(right);
  }
}
