import 'package:flutter/material.dart';
import 'package:purewill/features/habit/services/category_api_service.dart';
import 'package:purewill/features/habit/models/category_model.dart';

class CategoryListViewModel extends ChangeNotifier {
  final CategoryApiService apiService;
  List<CategoryModel> categories = [];
  List<CategoryModel> filtered = [];
  bool isLoading = false;
  String? error;

  CategoryListViewModel(this.apiService);

  Future<void> fetchCategories() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await apiService.getAllCategories();
      categories = result;
      filtered = result;
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  void searchCategory(String query) {
    if (query.isEmpty) {
      filtered = categories;
    } else {
      filtered = categories
          .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  Future<void> deleteCategory(int id) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await apiService.deleteCategory(id);
      await fetchCategories();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }
}
