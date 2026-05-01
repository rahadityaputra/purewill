import 'package:flutter_riverpod/legacy.dart';
import 'package:purewill/features/habit/providers/habit_provider.dart';
import 'package:purewill/features/habit/view_models/habit_detail_view_model.dart';

final habitDetailProvider =
    StateNotifierProvider<HabitDetailViewModel, HabitDetailState>((ref) {
      final habitApiService = ref.watch(habitApiServiceProvider);
      return HabitDetailViewModel(habitApiService);
    });
