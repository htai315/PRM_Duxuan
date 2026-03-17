import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/utils/date_ui.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/domain/entities/plan_day.dart';
import 'package:du_xuan/viewmodels/itinerary/itinerary_viewmodel.dart';
import 'package:du_xuan/views/itinerary/location_action_sheet.dart';
import 'package:du_xuan/views/shared/widgets/app_empty_state.dart';
import 'package:du_xuan/views/shared/widgets/app_loading_state.dart';

/// Tab 3: Tất cả địa điểm của plan, nhóm theo ngày.
class LocationsTab extends StatelessWidget {
  final ItineraryViewModel viewModel;

  const LocationsTab({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final groupedLocations = _buildDaysWithLocations();

        if (viewModel.isLoading && viewModel.plan == null) {
          return const AppLoadingState(
            title: 'Đang tải địa điểm',
            subtitle: 'Tổng hợp các điểm đến từ lịch trình hiện tại.',
            icon: Icons.place_rounded,
            compact: true,
          );
        }

        if (groupedLocations.isEmpty) {
          return const AppEmptyState(
            icon: Icons.place_rounded,
            title: 'Chưa có địa điểm nào',
            subtitle: 'Thêm địa điểm khi tạo hoạt động.',
            accentColor: AppColors.primary,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          itemCount: groupedLocations.length,
          itemBuilder: (context, index) {
            final entry = groupedLocations[index];
            return _daySection(entry.$1, entry.$2, context);
          },
        );
      },
    );
  }

  List<(PlanDay, List<Activity>)> _buildDaysWithLocations() {
    final entries = <(PlanDay, List<Activity>)>[];

    for (final day in viewModel.days) {
      final withLocation = viewModel.activitiesForDay(day.id).where((activity) {
        final location = activity.locationText?.trim();
        return location != null && location.isNotEmpty;
      }).toList();

      if (withLocation.isNotEmpty) {
        entries.add((day, withLocation));
      }
    }

    entries.sort((a, b) => a.$1.dayNumber.compareTo(b.$1.dayNumber));
    return entries;
  }

  Widget _daySection(
    PlanDay day,
    List<Activity> activities,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
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
                DateUi.shortDate(day.date),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 1, color: AppColors.divider)),
            ],
          ),
        ),
        ...activities.map((activity) => _locationCard(activity, context)),
      ],
    );
  }

  Widget _locationCard(Activity activity, BuildContext context) {
    return GestureDetector(
      onTap: () {
        final location = activity.locationText;
        if (location == null || location.isEmpty) return;
        LocationActionSheet.show(
          context: context,
          locationText: location,
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
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.place_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.locationText!,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.event_note_rounded,
                        size: 14,
                        color: AppColors.textLight,
                      ),
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
