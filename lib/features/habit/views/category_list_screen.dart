import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/features/habit/providers/category_unit_management_provider.dart';
import 'package:purewill/features/habit/views/create_category_screen.dart';
import 'package:purewill/features/habit/views/edit_category_screen.dart';
import 'package:purewill/core/widgets/app_view_widgets.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    await ref.read(categoryListViewModelProvider).fetchCategories();
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    int categoryId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final vm = ref.read(categoryListViewModelProvider);
    await vm.deleteCategory(categoryId);

    if (!context.mounted) return;
    if (vm.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(vm.error!)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(categoryListViewModelProvider);

    return Scaffold(
      appBar: ConsistentAppBar(
        title: 'Categories',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const CreateCategoryScreen()),
              );
              if (result == true) {
                await _refresh(ref);
              }
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: vm,
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search Category',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: vm.searchCategory,
                  ),
                ),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (vm.isLoading && vm.categories.isEmpty) {
                        return const AppLoadingView();
                      }
                      if (vm.error != null && vm.categories.isEmpty) {
                        return AppEmptyState(
                          icon: Icons.error_outline,
                          title: 'Error loading categories',
                          message: vm.error!,
                          actionLabel: 'Retry',
                          onAction: () => _refresh(ref),
                        );
                      }
                      if (vm.filtered.isEmpty) {
                        return const AppEmptyState(
                          icon: Icons.category_outlined,
                          title: 'No categories found',
                          message: 'Create a category to start organizing habits.',
                        );
                      }
                      return ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: vm.filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final category = vm.filtered[index];
                          return ListTile(
                            title: Text(category.name),
                            subtitle: Text(
                              category.description?.trim().isNotEmpty == true
                                  ? category.description!
                                  : 'No description',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () async {
                                    final result = await Navigator.of(context)
                                        .push<bool>(
                                          MaterialPageRoute(
                                            builder: (_) => EditCategoryScreen(
                                              categoryId: category.id,
                                            ),
                                          ),
                                        );
                                    if (result == true) {
                                      await _refresh(ref);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _showDeleteDialog(
                                    context,
                                    ref,
                                    category.id,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
