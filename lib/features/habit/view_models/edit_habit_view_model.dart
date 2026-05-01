import 'package:flutter_riverpod/legacy.dart';
import 'package:purewill/features/habit/services/habit_api_service.dart';
import 'package:purewill/features/user/services/me_api_service.dart';
import 'package:purewill/features/habit/models/category_model.dart';
import 'package:purewill/features/habit/view_models/habit_view_model.dart';

class EditHabitViewModel extends StateNotifier<HabitsState> {
  final HabitApiService _habitApiService;
  final MeApiService _meApiService;

  EditHabitViewModel(this._habitApiService, this._meApiService)
    : super(HabitsState());

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

  Future<void> updateHabitFields({
    required int habitId,
    required Map<String, dynamic> updates,
  }) async {
    if (updates.isEmpty) return;

    try {
      await _habitApiService.updateHabit(habitId, updates);
      // Optionally refresh categories or other related state here
      state = state.copyWith(status: HabitStatus.success, errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        status: HabitStatus.failure,
        errorMessage: 'Failed to edit habit.',
      );
      rethrow;
    }
  }
}
