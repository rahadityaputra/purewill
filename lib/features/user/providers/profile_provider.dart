import 'package:flutter_riverpod/legacy.dart';
import 'package:purewill/features/habit/providers/habit_provider.dart';
import 'package:purewill/features/user/view_models/profile_view_models.dart';

final profileViewModelProvider =
    StateNotifierProvider<ProfileViewModel, ProfileState>((ref) {
      ref.watch(habitTokenSyncProvider);
      final meService = ref.watch(meApiServiceProvider);
      final vm = ProfileViewModel(ref, meService);
      Future.microtask(vm.loadProfile);
      return vm;
    });
