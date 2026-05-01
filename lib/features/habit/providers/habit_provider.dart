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
  return HabitApiService(authRepository: ref.watch(authRepositoryProvider));
});

final categoryApiServiceProvider = Provider<CategoryApiService>((ref) {
  return CategoryApiService(authRepository: ref.watch(authRepositoryProvider));
});

final unitApiServiceProvider = Provider<UnitApiService>((ref) {
  return UnitApiService(authRepository: ref.watch(authRepositoryProvider));
});

final meApiServiceProvider = Provider<MeApiService>((ref) {
  return MeApiService(authRepository: ref.watch(authRepositoryProvider));
});

final nofapSessionApiServiceProvider = Provider<NofapSessionApiService>((ref) {
  return NofapSessionApiService(
    authRepository: ref.watch(authRepositoryProvider),
  );
});

final reminderApiServiceProvider = Provider<ReminderApiService>((ref) {
  return ReminderApiService(authRepository: ref.watch(authRepositoryProvider));
});

final motivationServiceProvider = Provider<MotivationService>((ref) {
  return MotivationService();
});

// ==================== TOKEN SYNC ====================
final habitTokenSyncProvider = Provider<void>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final habitService = ref.watch(habitApiServiceProvider);
  final categoryService = ref.watch(categoryApiServiceProvider);
  final unitService = ref.watch(unitApiServiceProvider);
  final meService = ref.watch(meApiServiceProvider);
  final reminderService = ref.watch(reminderApiServiceProvider);
  final nofapService = ref.watch(nofapSessionApiServiceProvider);
  final authRepo = ref.watch(authRepositoryProvider);

  if (authState.user != null && authRepo.accessToken != null) {
    habitService.setAccessToken(authRepo.accessToken!);
    categoryService.setAccessToken(authRepo.accessToken!);
    unitService.setAccessToken(authRepo.accessToken!);
    meService.setAccessToken(authRepo.accessToken!);
    reminderService.setAccessToken(authRepo.accessToken!);
    nofapService.setAccessToken(authRepo.accessToken!);
  }
});

// ==================== HABIT NOTIFIER ====================
final habitNotifierProvider =
    StateNotifierProvider<HabitsViewModel, HabitsState>((ref) {
      ref.watch(habitTokenSyncProvider);

      final habitApiService = ref.watch(habitApiServiceProvider);
      final meApiService = ref.watch(meApiServiceProvider);
      ref.listen(authNotifierProvider, (previous, next) {
        if (previous?.user?.id != next.user?.id) {
          ref.invalidateSelf();
          final authRepo = ref.read(authRepositoryProvider);
          final habitService = ref.read(habitApiServiceProvider);
          final meService = ref.read(meApiServiceProvider);
          final categoryService = ref.read(categoryApiServiceProvider);
          final unitService = ref.read(unitApiServiceProvider);
          if (authRepo.accessToken != null) {
            habitService.setAccessToken(authRepo.accessToken!);
            categoryService.setAccessToken(authRepo.accessToken!);
            unitService.setAccessToken(authRepo.accessToken!);
            meService.setAccessToken(authRepo.accessToken!);
          }
        }
      });

      return HabitsViewModel(habitApiService, meApiService);
    });

final homeNotifierProvider = StateNotifierProvider<HomeViewModel, HomeState>((
  ref,
) {
  ref.watch(habitTokenSyncProvider);

  final habitApiService = ref.watch(habitApiServiceProvider);
  final meApiService = ref.watch(meApiServiceProvider);

  ref.listen(authNotifierProvider, (previous, next) {
    if (previous?.user?.id != next.user?.id) {
      ref.invalidateSelf();
      final authRepo = ref.read(authRepositoryProvider);
      final habitService = ref.read(habitApiServiceProvider);
      final meService = ref.read(meApiServiceProvider);
      if (authRepo.accessToken != null) {
        habitService.setAccessToken(authRepo.accessToken!);
        meService.setAccessToken(authRepo.accessToken!);
      }
    }
  });

  return HomeViewModel(habitApiService, meApiService);
});

final addHabitNotifierProvider =
    StateNotifierProvider<AddHabitViewModel, AddHabitState>((ref) {
      ref.watch(habitTokenSyncProvider);

      final habitApiService = ref.watch(habitApiServiceProvider);
      final meApiService = ref.watch(meApiServiceProvider);

      ref.listen(authNotifierProvider, (previous, next) {
        if (previous?.user?.id != next.user?.id) {
          ref.invalidateSelf();
          final authRepo = ref.read(authRepositoryProvider);
          final habitService = ref.read(habitApiServiceProvider);
          final meService = ref.read(meApiServiceProvider);
          if (authRepo.accessToken != null) {
            habitService.setAccessToken(authRepo.accessToken!);
            meService.setAccessToken(authRepo.accessToken!);
          }
        }
      });

      return AddHabitViewModel(habitApiService, meApiService);
    });

final editHabitNotifierProvider =
    StateNotifierProvider<EditHabitViewModel, HabitsState>((ref) {
      ref.watch(habitTokenSyncProvider);

      final habitApiService = ref.watch(habitApiServiceProvider);
      final meApiService = ref.watch(meApiServiceProvider);

      ref.listen(authNotifierProvider, (previous, next) {
        if (previous?.user?.id != next.user?.id) {
          ref.invalidateSelf();
          final authRepo = ref.read(authRepositoryProvider);
          final habitService = ref.read(habitApiServiceProvider);
          final meService = ref.read(meApiServiceProvider);
          if (authRepo.accessToken != null) {
            habitService.setAccessToken(authRepo.accessToken!);
            meService.setAccessToken(authRepo.accessToken!);
          }
        }
      });

      return EditHabitViewModel(habitApiService, meApiService);
    });

final nofapNotifierProvider = StateNotifierProvider<NofapViewModel, NofapState>(
  (ref) {
    ref.watch(habitTokenSyncProvider);

    final nofapService = ref.watch(nofapSessionApiServiceProvider);
    final meService = ref.watch(meApiServiceProvider);
    final motivationService = ref.watch(motivationServiceProvider);

    ref.listen(authNotifierProvider, (previous, next) {
      if (previous?.user?.id != next.user?.id) {
        ref.invalidateSelf();
        final authRepo = ref.read(authRepositoryProvider);
        final service = ref.read(nofapSessionApiServiceProvider);
        final meService = ref.read(meApiServiceProvider);
        if (authRepo.accessToken != null) {
          service.setAccessToken(authRepo.accessToken!);
          meService.setAccessToken(authRepo.accessToken!);
        }
      }
    });

    return NofapViewModel(nofapService, meService, motivationService);
  },
);
