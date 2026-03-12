import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/di.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/domain/entities/plan_day.dart';
import 'package:du_xuan/views/itinerary/location_action_sheet.dart';
import 'package:intl/intl.dart';

/// Tab 3: Tất cả địa điểm của plan, nhóm theo ngày
class LocationsTab extends StatefulWidget {
  final int planId;
  final String planName;
  final int refreshToken;

  const LocationsTab({
    super.key,
    required this.planId,
    required this.planName,
    this.refreshToken = 0,
  });

  @override
  State<LocationsTab> createState() => _LocationsTabState();
}

class _LocationsTabState extends State<LocationsTab> {
  bool _isLoading = true;
  Map<PlanDay, List<Activity>> _daysWithLocations = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant LocationsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldReload = oldWidget.planId != widget.planId ||
        oldWidget.refreshToken != widget.refreshToken;
    if (shouldReload) {
      _loadData(showLoading: true);
    }
  }

  Future<void> _loadData({bool showLoading = false}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final planRepo = buildPlanRepository();
      final activityRepo = buildActivityRepository();
      final plan = await planRepo.getById(widget.planId);
      if (plan == null) {
        if (mounted) {
          setState(() {
            _daysWithLocations = {};
            _isLoading = false;
          });
        }
        return;
      }

      final result = <PlanDay, List<Activity>>{};
      for (final day in plan.days) {
        final activities = await activityRepo.getByPlanDayId(day.id);
        final withLocation = activities
            .where((a) => a.locationText != null && a.locationText!.isNotEmpty)
            .toList();
        if (withLocation.isNotEmpty) {
          result[day] = withLocation;
        }
      }

      if (mounted) {
        setState(() {
          _daysWithLocations = result;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_daysWithLocations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.place_rounded,
                  size: 30, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text('Chưa có địa điểm nào', style: AppTextStyles.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Thêm địa điểm khi tạo hoạt động',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      );
    }

    final dateFmt = DateFormat('dd/MM');
    final sortedDays = _daysWithLocations.keys.toList()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: sortedDays.length,
      itemBuilder: (context, i) {
        final day = sortedDays[i];
        final activities = _daysWithLocations[day]!;
        return _daySection(day, activities, dateFmt);
      },
    );
  }

  Widget _daySection(
      PlanDay day, List<Activity> activities, DateFormat dateFmt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'NGÀY ${day.dayNumber}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 1,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateFmt.format(day.date),
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMedium),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(height: 1, color: AppColors.divider),
              ),
            ],
          ),
        ),
        // Activity cards
        ...activities.map((a) => _locationCard(a)),
      ],
    );
  }

  Widget _locationCard(Activity activity) {
    return GestureDetector(
      onTap: () {
        LocationActionSheet.show(
          context: context,
          locationText: activity.locationText!,
          activityTitle: activity.title,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Activity type icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.place_rounded,
                  size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.locationText!,
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.event_note_rounded,
                          size: 14, color: AppColors.textLight),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          activity.title,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textLight,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.bgCream,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions_rounded,
                size: 16,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
