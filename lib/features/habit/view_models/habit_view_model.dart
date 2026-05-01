import 'package:flutter_riverpod/legacy.dart';
import 'package:purewill/features/habit/services/habit_api_service.dart';
import 'package:purewill/features/user/services/me_api_service.dart';
import 'package:purewill/features/habit/models/category_model.dart';
import 'package:purewill/features/habit/models/habit_log_model.dart';
import 'package:purewill/features/habit/models/habit_model.dart';
import 'package:purewill/features/user/models/profile_model.dart';
import 'package:purewill/features/habit/models/reminder_setting_model.dart';
import 'package:purewill/features/habit/models/target_unit_model.dart';
import 'package:purewill/core/utils/indonesia_timezone.dart';

enum HabitStatus { loading, success, failure }

class HabitsState {
  final HabitStatus status;
  final String? errorMessage;
  final List<HabitModel> habits;
  final List<HabitModel> todayHabit;
  final List<HabitLogModel> habitLogs;
  final List<TargetUnitModel> targetUnits;
  final List<CategoryModel> categories;
  final List<HabitLogModel> habitLogForThisMonth;
  final HabitModel? currentHabitDetail;

  final ReminderSettingModel? currentReminderSetting;
  ProfileModel? currentUser;

  HabitsState({
    this.status = HabitStatus.loading,
    this.errorMessage,
    this.habits = const [],
    this.todayHabit = const [],
    this.habitLogs = const [],
    this.targetUnits = const [],
    this.categories = const [],
    this.habitLogForThisMonth = const [],
    this.currentUser,
    this.currentHabitDetail,
    this.currentReminderSetting,
  });

  HabitsState copyWith({
    HabitStatus? status,
    String? errorMessage,
    List<HabitModel>? habits,
    List<HabitModel>? todayHabit,
    List<HabitLogModel>? habitLogs,
    List<HabitLogModel>? habitLogForThisMonth,
    List<TargetUnitModel>? targetUnits,
    List<CategoryModel>? categories,
    List<ReminderSettingModel>? reminderSettings,
    ProfileModel? currentUser,
    HabitModel? currentHabitDetail,
  }) {
    return HabitsState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      habits: habits ?? this.habits,
      todayHabit: todayHabit ?? this.todayHabit,
      habitLogs: habitLogs ?? this.habitLogs,
      habitLogForThisMonth: habitLogForThisMonth ?? this.habitLogForThisMonth,
      targetUnits: targetUnits ?? this.targetUnits,
      categories: categories ?? this.categories,
      currentUser: currentUser ?? this.currentUser,
      currentHabitDetail: currentHabitDetail ?? this.currentHabitDetail,
    );
  }
}

class HabitsViewModel extends StateNotifier<HabitsState> {
  final HabitApiService _habitApiService;
  final MeApiService _meApiService;
  HabitsViewModel(this._habitApiService, this._meApiService)
    : super(HabitsState());

  void clearState() {
    state = HabitsState(
      status: HabitStatus.loading,
      errorMessage: null,
      habits: const [],
      todayHabit: const [],
      habitLogs: const [],
      targetUnits: const [],
      categories: const [],
      currentUser: null,
      currentHabitDetail: null,
      currentReminderSetting: null,
    );
  }

  Future<List<HabitModel>> _fetchUserHabits() async {
    final response = await _meApiService.getMeHabits();
    final data = response['data'] as List? ?? [];
    return data.map((json) => HabitModel.fromJson(json)).toList();
  }


  Future<void> _updateHabit(int habitId, Map<String, dynamic> updates) async {
    await _habitApiService.updateHabit(habitId, updates);
  }

  Future<void> updateHabitFields({
    required int habitId,
    required Map<String, dynamic> updates,
  }) async {
    if (updates.isEmpty) {
      return;
    }

    try {
      await _updateHabit(habitId, updates);
      await loadUserHabits();
    } catch (e) {
      state = state.copyWith(
        status: HabitStatus.failure,
        errorMessage: 'Failed to edit habit.',
      );
      rethrow;
    }
  }


  Future<void> loadUserHabits() async {
    state = state.copyWith(status: HabitStatus.loading, errorMessage: null);

    try {
      final allHabits = await _fetchUserHabits();
      state = state.copyWith(status: HabitStatus.success, habits: allHabits);
    } catch (e) {
      state = state.copyWith(
        status: HabitStatus.failure,
        errorMessage: 'Failed to load habits.',
      );
    }
  }



  Future<void> loadCategories() async {
    state = state.copyWith(status: HabitStatus.loading, errorMessage: null);

    try {
      final response = await _meApiService.getMeCategories();
      final data = response['data'] as List? ?? [];

      final categories = data
          .whereType<Map>()
          .map(
            (json) => CategoryModel.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();

      state = state.copyWith(
        status: HabitStatus.success,
        categories: categories,
      );
    } catch (e) {
      state = state.copyWith(
        status: HabitStatus.failure,
        errorMessage: 'Failed to load categories.',
      );
    }
  }

  
  Future<Map<int, LogStatus>> getTodayCompletionStatus() async {
    try {
      final habits = state.habits.isNotEmpty
          ? state.habits
          : await _fetchUserHabits();

      if (habits.isEmpty) {
        return <int, LogStatus>{};
      }

      final today = nowInIndonesia();
      final todayOnly = dateOnlyInIndonesia(today);
      final completionStatus = <int, LogStatus>{};

      for (final habit in habits) {
        try {
          final response = await _habitApiService.getHabitLogs(
            habitId: habit.id,
          );
          final data = response['data'] as List? ?? [];

          final logs = data
              .whereType<Map>()
              .map(
                (json) =>
                    HabitLogModel.fromJson(Map<String, dynamic>.from(json)),
              )
              .toList();

          if (logs.isEmpty) {
            completionStatus[habit.id] = LogStatus.neutral;
            continue;
          }

          final todayLogs = logs.where((log) {
            final d = log.logDate;
            final logOnly = dateOnlyInIndonesia(d);
            return logOnly == todayOnly;
          }).toList();

          if (todayLogs.isEmpty) {
            completionStatus[habit.id] = LogStatus.neutral;
            continue;
          }

          todayLogs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          completionStatus[habit.id] = todayLogs.first.status;
        } catch (e) {
          completionStatus[habit.id] = LogStatus.neutral;
        }
      }

      state = state.copyWith(habitLogs: const []);
      return completionStatus;
    } catch (e) {
      return {};
    }
  }

}
