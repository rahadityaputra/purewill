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
    final headerColor = _resolveHeaderColor(habit);
    final isHeaderDark =
        ThemeData.estimateBrightnessForColor(headerColor) == Brightness.dark;
    final headerForegroundColor = isHeaderDark ? Colors.white : Colors.black87;

    if (habitDetailState.status == HabitStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: headerColor,
              elevation: 0,
              pinned: true,
              expandedHeight: 140,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeaderBackground(headerColor),
                titlePadding: const EdgeInsets.only(
                  left: 0,
                  right: 0,
                  bottom: 0,
                ),
                collapseMode: CollapseMode.pin,
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: headerForegroundColor),
                onPressed: () => Navigator.pop(context, _shouldRefreshParent),
              ),
              title: Text(
                habitName,
                style: TextStyle(
                  color: headerForegroundColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              actions: [
                HabitActionsDropdown(
                  iconColor: headerForegroundColor,
                  onActionSelected: _handleMenuAction,
                  habitName: habit.name,
                  habit: habit,
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HabitDetailExplanationWidget(
                      habit: habit,
                      habitColor: iconColor,
                    ),

                    const SizedBox(height: 24),

                    ValueEarnedWidget(
                      habit: habit,
                      habitLogs: habitDetailState.habitLogs,
                      habitColor: iconColor,
                    ),

                    const SizedBox(height: 24),

                    ProgressWidget(
                      isCompleted: _isTodayCompleted(
                        habitDetailState.habitLogs,
                      ),
                      habitColor: iconColor,
                      habitName: habit.name,
                      completedDays: habitDetailState.completedDays,
                      totalDays: habitDetailState.possibleDays,
                    ),

                    const SizedBox(height: 24),

                    WeeklyStreakWidget(streak: habitDetailState.habitLogStreak),

                    const SizedBox(height: 24),

                    BestStreakWidget(
                      streak: habitDetailState.bestHabitLogStreak,
                    ),

                    const SizedBox(height: 24),

                    CalendarTrackerWidget(
                      habitLogForThisMonth:
                          habitDetailState.habitLogForThisMonth,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
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

  Future<bool> _handleWillPop() async {
    Navigator.pop(context, _shouldRefreshParent);
    return false;
  }

  Widget _buildHeaderBackground(Color headerColor) {
    return Container(color: headerColor);
  }

  Color _resolveHeaderColor(HabitModel habit) {
    final parsedCategoryColor = _parseCategoryColor(habit.category?.color);
    if (parsedCategoryColor != null) {
      return parsedCategoryColor;
    }

    final fallbackCategoryName =
        habit.category?.name ?? HabitIconHelper.getHabitCategory(habit.name);
    return HabitIconHelper.getHabitColor(fallbackCategoryName);
  }

  Color? _parseCategoryColor(String? rawColor) {
    if (rawColor == null || rawColor.trim().isEmpty) {
      return null;
    }

    var hex = rawColor.trim().replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length != 8) {
      return null;
    }

    final value = int.tryParse(hex, radix: 16);
    if (value == null) {
      return null;
    }

    return Color(value);
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
