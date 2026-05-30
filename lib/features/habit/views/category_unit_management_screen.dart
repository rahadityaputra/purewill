import 'package:flutter/material.dart';
import 'package:purewill/features/habit/views/category_list_screen.dart';
import 'package:purewill/features/habit/views/unit_list_screen.dart';
import 'package:purewill/core/widgets/app_view_widgets.dart';

class CategoryUnitManagementScreen extends StatelessWidget {
  const CategoryUnitManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const ConsistentAppBar(
          title: 'Category & Unit Management',
          bottom: TabBar(
            tabs: [
              Tab(text: 'Category'),
              Tab(text: 'Unit'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [CategoryListScreen(), UnitListScreen()],
        ),
      ),
    );
  }
}
