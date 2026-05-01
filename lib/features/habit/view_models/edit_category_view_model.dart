import 'package:flutter/material.dart';
import 'package:purewill/features/habit/services/category_api_service.dart';
import 'package:purewill/features/habit/models/category_model.dart';

class EditCategoryViewModel extends ChangeNotifier {
  final CategoryApiService apiService;
  bool isLoading = false;
  String? error;
  CategoryModel? category;
  String? successMessage;

  EditCategoryViewModel(this.apiService);

  Future<void> loadDetail(int id) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      category = await apiService.getCategoryDetail(id);
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> submitUpdate({
    required int id,
    required String name,
    String? description,
  }) async {
    isLoading = true;
    error = null;
    successMessage = null;
    notifyListeners();
    try {
      await apiService.updateCategory(
        id: id,
        name: name,
        description: description,
      );
      isLoading = false;
      successMessage = 'Category updated successfully';
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
