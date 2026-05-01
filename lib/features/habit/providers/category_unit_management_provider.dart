import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/features/habit/providers/habit_provider.dart';
import 'package:purewill/features/habit/view_models/category_list_view_model.dart';
import 'package:purewill/features/habit/view_models/create_category_view_model.dart';
import 'package:purewill/features/habit/view_models/edit_category_view_model.dart';
import 'package:purewill/features/habit/view_models/unit_list_viewmodel.dart';
import 'package:purewill/features/habit/view_models/create_unit_view_model.dart';
import 'package:purewill/features/habit/view_models/edit_unit_view_model.dart';

final categoryListViewModelProvider = Provider<CategoryListViewModel>((ref) {
  final api = ref.watch(categoryApiServiceProvider);
  final vm = CategoryListViewModel(api);
  Future.microtask(vm.fetchCategories);
  return vm;
});

final createCategoryViewModelProvider = Provider<CreateCategoryViewModel>((
  ref,
) {
  final api = ref.watch(categoryApiServiceProvider);
  return CreateCategoryViewModel(api);
});

final editCategoryViewModelProvider = Provider<EditCategoryViewModel>((ref) {
  final api = ref.watch(categoryApiServiceProvider);
  return EditCategoryViewModel(api);
});

final unitListViewModelProvider = Provider<UnitListViewModel>((ref) {
  final api = ref.watch(unitApiServiceProvider);
  final vm = UnitListViewModel(api);
  Future.microtask(vm.fetchUnits);
  return vm;
});

final createUnitViewModelProvider = Provider<CreateUnitViewModel>((ref) {
  final api = ref.watch(unitApiServiceProvider);
  return CreateUnitViewModel(api);
});

final editUnitViewModelProvider = Provider<EditUnitViewModel>((ref) {
  final api = ref.watch(unitApiServiceProvider);
  return EditUnitViewModel(api);
});
