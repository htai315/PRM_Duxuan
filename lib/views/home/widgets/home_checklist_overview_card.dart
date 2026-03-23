import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/domain/entities/checklist_item.dart';

class HomeChecklistOverviewCard extends StatelessWidget {
  final bool isLoading;
  final int packedCount;
  final int totalCount;
  final List<ChecklistItem> remainingItems;
  final VoidCallback onTap;

  const HomeChecklistOverviewCard({
    super.key,
    required this.isLoading,
    required this.packedCount,
    required this.totalCount,
    required this.remainingItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : packedCount / totalCount;
    final remainingCount = (totalCount - packedCount).clamp(0, totalCount);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.82)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.checklist_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tiến độ chuẩn bị',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          totalCount == 0
                              ? 'Chưa có vật dụng nào trong checklist'
                              : 'Đã chuẩn bị $packedCount/$totalCount vật dụng',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      totalCount == 0 ? '0%' : '${(progress * 100).round()}%',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: totalCount == 0 ? 0 : progress,
                  minHeight: 7,
                  backgroundColor: AppColors.bgWarm,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (isLoading)
                Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.primary.withValues(alpha: 0.8),
                    ),
                  ),
                )
              else if (totalCount == 0)
                Text(
                  'Thêm checklist để theo dõi đồ cần mang ngay từ kế hoạch này.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                    height: 1.35,
                  ),
                )
              else if (remainingItems.isEmpty)
                Text(
                  'Mọi thứ đã sẵn sàng. Bạn có thể yên tâm cho chuyến đi này.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                )
              else ...[
                Text(
                  'Còn $remainingCount vật dụng cần chuẩn bị:',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: remainingItems
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgCream,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.divider.withValues(alpha: 0.86),
                            ),
                          ),
                          child: Text(
                            item.quantity > 1
                                ? '${item.name} x${item.quantity}'
                                : item.name,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMedium,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
