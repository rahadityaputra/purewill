import 'package:flutter/material.dart';
import 'package:purewill/features/habit/models/category_model.dart';
import 'package:purewill/features/habit/models/habit_model.dart';

class HabitCard extends StatelessWidget {
  final String title;
  final Color color;
  final TodayLogStatus status;
  final CategoryModel category;
  final VoidCallback? onTap;
  final VoidCallback? onCheckboxTap;

  const HabitCard({
    super.key,
    required this.title,
    required this.color,
    required this.status,
    required this.category,
    this.onTap,
    this.onCheckboxTap,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = _parseColor(category.color) ?? color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: status == TodayLogStatus.success
                                ? Colors.grey
                                : Colors.black,
                            decoration: status == TodayLogStatus.success
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: badgeColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IgnorePointer(
              ignoring: false,
              child: GestureDetector(
                onTap: onCheckboxTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: status == TodayLogStatus.success
                        ? Colors.green
                        : status == TodayLogStatus.failed
                        ? Colors.red
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: status == TodayLogStatus.success
                          ? Colors.green
                          : status == TodayLogStatus.failed
                          ? Colors.red
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: status == TodayLogStatus.success
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : status == TodayLogStatus.failed
                      ? const Icon(Icons.close, color: Colors.white, size: 20)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color? _parseColor(String? value) {
    if (value == null || value.isEmpty) return null;

    final normalized = value.replaceAll('#', '').trim();
    final hexValue = normalized.length == 6 ? 'FF$normalized' : normalized;

    if (hexValue.length != 8) return null;

    final parsed = int.tryParse(hexValue, radix: 16);
    if (parsed == null) return null;

    return Color(parsed);
  }
}
