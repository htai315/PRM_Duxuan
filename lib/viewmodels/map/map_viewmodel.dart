import 'package:flutter/material.dart';
import 'package:du_xuan/core/enums/plan_status.dart';
import 'package:du_xuan/data/implementations/api/geocoding_service.dart';
import 'package:du_xuan/data/interfaces/repositories/i_activity_repository.dart';
import 'package:du_xuan/data/interfaces/repositories/i_plan_repository.dart';
import 'package:du_xuan/domain/entities/plan.dart';
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
  }) : _planRepo = planRepo,
       _activityRepo = activityRepo,
       _geocodingService = geocodingService;

  // ─── State ────────────────────────────────────────────
  List<MapMarkerData> _markers = [];
  List<String> _unresolvedLocations = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _ongoingPlanCount = 0;
  bool _hasLoaded = false;
  int? _lastLoadedUserId;
  int? _loadingUserId;
  int _activeRequestId = 0;

  // ─── Getters ──────────────────────────────────────────
  List<MapMarkerData> get markers => _markers;
  List<String> get unresolvedLocations => _unresolvedLocations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasOngoingPlans => _ongoingPlanCount > 0;
  int get ongoingPlanCount => _ongoingPlanCount;
  bool get hasLoaded => _hasLoaded;

  // ─── Actions ──────────────────────────────────────────

  /// Load địa điểm từ các kế hoạch đang diễn ra của user → geocode → markers.
  Future<void> loadMarkers(int userId, {bool force = false}) async {
    if (userId <= 0) {
      clear();
      return;
    }
    if (!force && _hasLoaded && _lastLoadedUserId == userId) {
      return;
    }
    if (!force && _isLoading && _loadingUserId == userId) {
      return;
    }

    final requestId = ++_activeRequestId;
    _loadingUserId = userId;

    _isLoading = true;
    _errorMessage = null;
    _unresolvedLocations = [];
    notifyListeners();

    try {
      final plans = await _planRepo.getMyPlans(userId);
      if (!_isActiveRequest(requestId)) return;

      final ongoingPlans = plans.where(_isPlanOngoing).toList();
      _ongoingPlanCount = ongoingPlans.length;

      if (ongoingPlans.isEmpty) {
        _markers = [];
        _unresolvedLocations = [];
        _hasLoaded = true;
        _lastLoadedUserId = userId;
        return;
      }

      final mergedGroups = <_MarkerGroup>[];
      final unresolvedSet = <String>{};

      // Thu thập locationText unique theo key chuẩn hoá trong từng plan.
      final locationBuckets = <String, _LocationBucket>{};

      for (final plan in ongoingPlans) {
        // Load full plan with days
        final fullPlan = await _planRepo.getById(plan.id);
        if (!_isActiveRequest(requestId)) return;
        if (fullPlan == null) continue;

        for (final day in fullPlan.days) {
          final activities = await _activityRepo.getByPlanDayId(day.id);
          if (!_isActiveRequest(requestId)) return;
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
        if (!_isActiveRequest(requestId)) return;
        if (point != null) {
          _mergeResolvedBucket(mergedGroups, bucket, point);
        } else {
          unresolvedSet.add(bucket.displayLocation);
        }

        // Delay giữa mỗi geocode request (Nominatim rate limit)
        await Future.delayed(const Duration(milliseconds: 1100));
        if (!_isActiveRequest(requestId)) return;
      }

      _markers = mergedGroups.map(_toMapMarker).toList();
      _unresolvedLocations = unresolvedSet.toList()..sort();
      _hasLoaded = true;
      _lastLoadedUserId = userId;
    } catch (e) {
      if (!_isActiveRequest(requestId)) return;
      _errorMessage = 'Không thể tải dữ liệu bản đồ';
      debugPrint('❌ MapViewModel error: $e');
    } finally {
      if (_isActiveRequest(requestId)) {
        _isLoading = false;
        _loadingUserId = null;
        notifyListeners();
      }
    }
  }

  void clear() {
    _activeRequestId++;
    _markers = [];
    _unresolvedLocations = [];
    _errorMessage = null;
    _isLoading = false;
    _ongoingPlanCount = 0;
    _hasLoaded = false;
    _lastLoadedUserId = null;
    _loadingUserId = null;
    notifyListeners();
  }

  void invalidateCache() {
    _hasLoaded = false;
    _lastLoadedUserId = null;
  }

  bool _isActiveRequest(int requestId) => requestId == _activeRequestId;

  bool _isPlanOngoing(Plan plan) {
    // Cho phép hiển thị cả plan đã bấm "hoàn thành" miễn là đang trong khung ngày.
    if (plan.status == PlanStatus.draft || plan.status == PlanStatus.archived) {
      return false;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      plan.startDate.year,
      plan.startDate.month,
      plan.startDate.day,
    );
    final end = DateTime(
      plan.endDate.year,
      plan.endDate.month,
      plan.endDate.day,
    );

    return !today.isBefore(start) && !today.isAfter(end);
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

  const _ActivityInfo({required this.title});
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
