import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/features/habit/models/habit_log_model.dart';
import 'package:purewill/features/habit/models/habit_model.dart';
import 'package:purewill/features/habit/providers/habit_detail_provider.dart';
import 'package:purewill/features/habit/views/edit_habit_screen.dart';
import 'package:purewill/features/habit/views/reminder_list_screen.dart';
import 'package:purewill/features/habit/view_models/habit_detail_view_model.dart';
import 'package:purewill/core/utils/habit_icon_helper.dart';
import 'package:purewill/core/utils/indonesia_timezone.dart';
import 'package:purewill/features/habit/widgets/best_streak_widget.dart';
import 'package:purewill/features/habit/widgets/calendar_tracker_widget.dart';
import 'package:purewill/features/habit/widgets/habit_actions_dropdown.dart';
import 'package:purewill/features/habit/widgets/habit_detail_explanation_widget.dart';
import 'package:purewill/features/habit/widgets/progress_widget.dart';
import 'package:purewill/features/habit/widgets/value_earned_widget.dart';
import 'package:purewill/features/habit/widgets/weekly_streak_widget.dart';
import 'package:purewill/core/widgets/app_view_widgets.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  final HabitModel habit;
  final Map<int, LogStatus> completionStatus;
  const HabitDetailScreen({
    super.key,
    required this.habit,
    required this.completionStatus,
  });

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  bool _shouldRefreshParent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(habitDetailProvider.notifier)
          .loadHabitDetailData(habitId: widget.habit.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitDetailState = ref.watch(habitDetailProvider);
    final habit = habitDetailState.currentHabitDetail ?? widget.habit;
    final habitName = habit.name;
    final iconColor = HabitIconHelper.getHabitColor(habit.name);

    if (habitDetailState.status == HabitStatus.loading) {
      return const Scaffold(body: AppLoadingView());
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _shouldRefreshParent);
      },
      child: Scaffold(
        appBar: ConsistentAppBar(
          title: habitName,
          actions: [
            HabitActionsDropdown(
              iconColor: Colors.black87,
              onActionSelected: _handleMenuAction,
              habitName: habit.name,
              habit: habit,
            ),
          ],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/home/bg.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(color: Colors.black.withValues(alpha: 0.08)),
              ),
            ),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ConsistentSectionCard(
                    child: HabitDetailExplanationWidget(
                      habit: habit,
                      habitColor: iconColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConsistentSectionCard(
                    child: ValueEarnedWidget(
                      habit: habit,
                      habitLogs: habitDetailState.habitLogs,
                      habitColor: iconColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConsistentSectionCard(
                    child: ProgressWidget(
                      isCompleted: _isTodayCompleted(
                        habitDetailState.habitLogs,
                      ),
                      habitColor: iconColor,
                      habitName: habit.name,
                      completedDays: habitDetailState.completedDays,
                      totalDays: habitDetailState.possibleDays,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConsistentSectionCard(
                    child: WeeklyStreakWidget(
                      streak: habitDetailState.habitLogStreak,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConsistentSectionCard(
                    child: BestStreakWidget(
                      streak: habitDetailState.bestHabitLogStreak,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConsistentSectionCard(
                    child: CalendarTrackerWidget(
                      habitLogForThisMonth:
                          habitDetailState.habitLogForThisMonth,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String value) {
    final habit =
        ref.read(habitDetailProvider).currentHabitDetail ?? widget.habit;

    HabitActionsDropdown.handleMenuAction(
      value: value,
      context: context,
      habitName: habit.name,
      habit: habit,
      onEdit: _editHabit,
      onReminder: _setReminder,
      onDelete: _deleteHabit,
    );
  }

  Future<void> _editHabit() async {
    final edited = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditHabitScreen(
          habit:
              ref.read(habitDetailProvider).currentHabitDetail ?? widget.habit,
        ),
      ),
    );

    if (!mounted || edited != true) {
      return;
    }

    _shouldRefreshParent = true;

    await ref
        .read(habitDetailProvider.notifier)
        .loadHabitDetailData(habitId: widget.habit.id);
  }

  void _setReminder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderListScreen(
          habit:
              ref.read(habitDetailProvider).currentHabitDetail ?? widget.habit,
        ),
      ),
    );
  }

  void _deleteHabit() {
    HabitActionsDropdown.showDeleteConfirmationDialog(
      context: context,
      habitName:
          (ref.read(habitDetailProvider).currentHabitDetail ?? widget.habit)
              .name,
      onConfirm: () {
        _performDeleteHabit();
      },
    );
  }

  Future<void> _performDeleteHabit() async {
    try {
      final viewModel = ref.read(habitDetailProvider.notifier);
      final habit =
          ref.read(habitDetailProvider).currentHabitDetail ?? widget.habit;

      if (habit.isDefault) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"${habit.name}" is a default habit and cannot be deleted',
            ),
          ),
        );
        return;
      }
      await viewModel.deleteHabit(habitId: habit.id);

      _shouldRefreshParent = true;

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${habit.name}" deleted successfully')),
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete habit: $e')));
    }
  }

  bool _isTodayCompleted(List<HabitLogModel> logs) {
    final today = dateOnlyInIndonesia(nowInIndonesia());

    final todayLogs = logs.where((log) {
      final date = dateOnlyInIndonesia(log.logDate);
      return date == today;
    });

    return todayLogs.any((log) => log.status == LogStatus.success);
  }
}
