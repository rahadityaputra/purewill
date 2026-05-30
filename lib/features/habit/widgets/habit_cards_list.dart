import 'package:flutter/material.dart';
import 'package:purewill/features/habit/models/category_model.dart';
import 'package:purewill/features/habit/models/habit_log_model.dart';
import 'package:purewill/features/habit/models/habit_model.dart';
import 'package:purewill/features/habit/view_models/habit_view_model.dart';
import 'package:purewill/core/utils/habit_icon_helper.dart';
import 'package:purewill/features/habit/widgets/habit_card.dart';

class HabitCardsList extends StatelessWidget {
  final HabitStatus status;
  final String? errorMessage;
  final Map<int, LogStatus> todayCompletionStatus;
  final List<HabitModel> habits;
  final void Function(HabitModel habit) onHabitTap;
  final void Function(HabitModel habit) onCheckboxTap;
  final Widget Function(String errorMessage)? buildErrorState;
  final Widget Function()? buildEmptyState;

  const HabitCardsList({
    super.key,
    required this.status,
    this.errorMessage,
    required this.todayCompletionStatus,
    required this.habits,
    required this.onHabitTap,
    required this.onCheckboxTap,
    this.buildErrorState,
    this.buildEmptyState,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case HabitStatus.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        );

      case HabitStatus.failure:
        return buildErrorState?.call(errorMessage ?? 'Unknown error') ??
            _defaultErrorState(errorMessage ?? 'Unknown error');

      case HabitStatus.success:
        if (habits.isEmpty) {
          return buildEmptyState?.call() ?? _defaultEmptyState();
        }

        final userHabits = habits.where((h) => !h.isDefault).toList();

        return Column(
          children: userHabits.map((habit) {
            final todayLogStatus = _resolveTodayLogStatus(habit);
            final categoryName = _determineCategory(habit);
            final color = HabitIconHelper.getHabitColor(categoryName);
            final category =
                habit.category ??
                CategoryModel(
                  id: 0,
                  name: categoryName,
                  color: null,
                  createdAt: DateTime.now(),
                );

            return HabitCard(
              title: habit.name,
              color: color,
              status: todayLogStatus,
              category: category,
              onTap: () => onHabitTap(habit),
              onCheckboxTap: () => onCheckboxTap(habit),
            );
          }).toList(),
        );
    }
  }

  TodayLogStatus _resolveTodayLogStatus(HabitModel habit) {
    final localStatus = todayCompletionStatus[habit.id];
    if (localStatus == null) {
      return habit.todayLogStatus;
    }

    switch (localStatus) {
      case LogStatus.success:
        return TodayLogStatus.success;
      case LogStatus.failed:
        return TodayLogStatus.failed;
      case LogStatus.neutral:
        return TodayLogStatus.netural;
    }
  }

  String _determineCategory(HabitModel habit) {
    final categoryId = habit.category?.id;
    if (categoryId != null) {
      final categoryName = _mapCategoryIdToName(categoryId);
      return categoryName;
    }

    final categoryFromName = HabitIconHelper.getHabitCategory(habit.name);
    return categoryFromName;
  }

  String _mapCategoryIdToName(int categoryId) {
    switch (categoryId) {
      case 1:
        return "Health & Fitness";
      case 2:
        return "Learning & Education";
      case 3:
        return "Productivity";
      case 4:
        return "Mindfulness & Mental Health";
      case 5:
        return "Personal Care";
      case 6:
        return "Social & Relationships";
      case 7:
        return "Finance";
      case 8:
        return "Hobbies & Creativity";
      case 9:
        return "Work & Career";
      case 10:
        return "Other";
      default:
        return "Other";
    }
  }

  Widget _defaultErrorState(String message) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 8),
        const Text(
          'Failed to load habits',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
      ],
    ),
  );

  Widget _defaultEmptyState() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.inbox_outlined, color: Colors.grey, size: 48),
        const SizedBox(height: 8),
        const Text(
          'No habits yet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add your first habit to get started!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
}
