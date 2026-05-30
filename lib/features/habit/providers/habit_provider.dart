import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:purewill/features/habit/services/category_api_service.dart';
import 'package:purewill/features/habit/services/habit_api_service.dart';
import 'package:purewill/features/habit/services/reminder_api_service.dart';
import 'package:purewill/features/user/services/me_api_service.dart';
import 'package:purewill/features/habit/services/motivation_service.dart';
import 'package:purewill/features/nofap/services/nofap_session_api_service.dart';
import 'package:purewill/features/habit/services/unit_api_service.dart';
import 'package:purewill/features/habit/view_models/add_habit_view_model.dart';
import 'package:purewill/features/habit/view_models/habit_view_model.dart';
import 'package:purewill/features/habit/view_models/edit_habit_view_model.dart';
import 'package:purewill/features/home/view_models/home_view_model.dart';
import 'package:purewill/features/nofap/view_models/nofap_view_model.dart';
import 'package:purewill/features/auth/providers/auth_provider.dart';

final habitApiServiceProvider = Provider<HabitApiService>((ref) {
  return HabitApiService(client: ref.watch(httpClientProvider));
});

final categoryApiServiceProvider = Provider<CategoryApiService>((ref) {
  return CategoryApiService(client: ref.watch(httpClientProvider));
});

final unitApiServiceProvider = Provider<UnitApiService>((ref) {
  return UnitApiService(client: ref.watch(httpClientProvider));
});

final meApiServiceProvider = Provider<MeApiService>((ref) {
  return MeApiService(client: ref.watch(httpClientProvider));
});

final nofapSessionApiServiceProvider = Provider<NofapSessionApiService>((ref) {
  return NofapSessionApiService(client: ref.watch(httpClientProvider));
});

final reminderApiServiceProvider = Provider<ReminderApiService>((ref) {
  return ReminderApiService(client: ref.watch(httpClientProvider));
});

final motivationServiceProvider = Provider<MotivationService>((ref) {
  return MotivationService();
});
final habitTokenSyncProvider = Provider<void>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final habitService = ref.watch(habitApiServiceProvider);
  final categoryService = ref.watch(categoryApiServiceProvider);
  final unitService = ref.watch(unitApiServiceProvider);
  final meService = ref.watch(meApiServiceProvider);
  final reminderService = ref.watch(reminderApiServiceProvider);
  final nofapService = ref.watch(nofapSessionApiServiceProvider);
  final authService = ref.watch(authServiceProvider);

  if (authState.user != null && authService.accessToken != null) {
    habitService.setAccessToken(authService.accessToken!);
    categoryService.setAccessToken(authService.accessToken!);
    unitService.setAccessToken(authService.accessToken!);
    meService.setAccessToken(authService.accessToken!);
    reminderService.setAccessToken(authService.accessToken!);
    nofapService.setAccessToken(authService.accessToken!);
  }
});
final StateNotifierProvider<HabitsViewModel, HabitsState>
habitNotifierProvider = StateNotifierProvider<HabitsViewModel, HabitsState>((
  ref,
) {
  ref.watch(habitTokenSyncProvider);

  final habitApiService = ref.watch(habitApiServiceProvider);
  final meApiService = ref.watch(meApiServiceProvider);
  final viewModel = HabitsViewModel(habitApiService, meApiService);
  ref.listen(authNotifierProvider, (previous, next) {
    if (previous?.user?.id != next.user?.id) {
      viewModel.clearState();
      final authService = ref.read(authServiceProvider);
      final habitService = ref.read(habitApiServiceProvider);
      final meService = ref.read(meApiServiceProvider);
      final categoryService = ref.read(categoryApiServiceProvider);
      final unitService = ref.read(unitApiServiceProvider);
      if (authService.accessToken != null) {
        habitService.setAccessToken(authService.accessToken!);
        categoryService.setAccessToken(authService.accessToken!);
        unitService.setAccessToken(authService.accessToken!);
        meService.setAccessToken(authService.accessToken!);
      }
    }
  });

  return viewModel;
});

final StateNotifierProvider<HomeViewModel, HomeState> homeNotifierProvider =
    StateNotifierProvider<HomeViewModel, HomeState>((ref) {
      ref.watch(habitTokenSyncProvider);

      final habitApiService = ref.watch(habitApiServiceProvider);
      final meApiService = ref.watch(meApiServiceProvider);
      final viewModel = HomeViewModel(habitApiService, meApiService);

      ref.listen(authNotifierProvider, (previous, next) {
        if (previous?.user?.id != next.user?.id) {
          viewModel.reset();
          final authService = ref.read(authServiceProvider);
          final habitService = ref.read(habitApiServiceProvider);
          final meService = ref.read(meApiServiceProvider);
          if (authService.accessToken != null) {
            habitService.setAccessToken(authService.accessToken!);
            meService.setAccessToken(authService.accessToken!);
          }
        }
      });

      return viewModel;
    });

final StateNotifierProvider<AddHabitViewModel, AddHabitState>
addHabitNotifierProvider =
    StateNotifierProvider<AddHabitViewModel, AddHabitState>((ref) {
      ref.watch(habitTokenSyncProvider);

      final habitApiService = ref.watch(habitApiServiceProvider);
      final meApiService = ref.watch(meApiServiceProvider);
      final viewModel = AddHabitViewModel(habitApiService, meApiService);

      ref.listen(authNotifierProvider, (previous, next) {
        if (previous?.user?.id != next.user?.id) {
          viewModel.reset();
          final authService = ref.read(authServiceProvider);
          final habitService = ref.read(habitApiServiceProvider);
          final meService = ref.read(meApiServiceProvider);
          if (authService.accessToken != null) {
            habitService.setAccessToken(authService.accessToken!);
            meService.setAccessToken(authService.accessToken!);
          }
        }
      });

      return viewModel;
    });

final StateNotifierProvider<EditHabitViewModel, HabitsState>
editHabitNotifierProvider =
    StateNotifierProvider<EditHabitViewModel, HabitsState>((ref) {
      ref.watch(habitTokenSyncProvider);

      final habitApiService = ref.watch(habitApiServiceProvider);
      final meApiService = ref.watch(meApiServiceProvider);
      final viewModel = EditHabitViewModel(habitApiService, meApiService);

      ref.listen(authNotifierProvider, (previous, next) {
        if (previous?.user?.id != next.user?.id) {
          viewModel.reset();
          final authService = ref.read(authServiceProvider);
          final habitService = ref.read(habitApiServiceProvider);
          final meService = ref.read(meApiServiceProvider);
          if (authService.accessToken != null) {
            habitService.setAccessToken(authService.accessToken!);
            meService.setAccessToken(authService.accessToken!);
          }
        }
      });

      return viewModel;
    });

final StateNotifierProvider<NofapViewModel, NofapState> nofapNotifierProvider =
    StateNotifierProvider<NofapViewModel, NofapState>((ref) {
      ref.watch(habitTokenSyncProvider);

      final nofapService = ref.watch(nofapSessionApiServiceProvider);
      final meService = ref.watch(meApiServiceProvider);
      final motivationService = ref.watch(motivationServiceProvider);
      final viewModel = NofapViewModel(
        nofapService,
        meService,
        motivationService,
      );

      ref.listen(authNotifierProvider, (previous, next) {
        if (previous?.user?.id != next.user?.id) {
          viewModel.reset();
          final authService = ref.read(authServiceProvider);
          final service = ref.read(nofapSessionApiServiceProvider);
          final meService = ref.read(meApiServiceProvider);
          if (authService.accessToken != null) {
            service.setAccessToken(authService.accessToken!);
            meService.setAccessToken(authService.accessToken!);
          }
        }
      });

      return viewModel;
    });
