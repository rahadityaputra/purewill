import 'package:flutter/material.dart';
import 'package:purewill/features/habit/models/habit_model.dart';
import 'package:purewill/features/habit/views/edit_habit_screen.dart';
import 'package:purewill/features/habit/views/reminder_list_screen.dart';
import 'package:purewill/core/widgets/dialogs/app_confirm_dialog.dart';

class HabitActionsDropdown extends StatelessWidget {
  final Function(String) onActionSelected;
  final String habitName;
  final HabitModel habit;
  final Color iconColor;

  const HabitActionsDropdown({
    super.key,
    required this.onActionSelected,
    required this.habitName,
    required this.habit,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: iconColor),
      onSelected: onActionSelected,
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('Edit Habit'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'reminder',
          child: Row(
            children: [
              Icon(Icons.notifications, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text('Reminder Settings'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Delete Habit'),
            ],
          ),
        ),
      ],
    );
  }

  static void showDeleteConfirmationDialog({
    required BuildContext context,
    required String habitName,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AppConfirmDialog(
        title: 'Delete Habit',
        message: 'Are you sure you want to delete "$habitName"?',
        confirmLabel: 'Delete',
        confirmColor: Colors.red,
        onConfirm: onConfirm,
      ),
    );
  }

  static void handleMenuAction({
    required String value,
    required BuildContext context,
    required String habitName,
    required HabitModel habit,
    VoidCallback? onEdit,
    VoidCallback? onReminder,
    VoidCallback? onDelete,
  }) {
    switch (value) {
      case 'edit':
        if (onEdit != null) {
          onEdit();
        } else {
          _navigateToEditScreen(context, habit);
        }
        break;
      case 'reminder':
        if (onReminder != null) {
          onReminder();
        } else {
          _navigateToReminderSettings(context, habit);
        }
        break;
      case 'delete':
        if (onDelete != null) {
          onDelete();
        } else {
          showDeleteConfirmationDialog(
            context: context,
            habitName: habitName,
            onConfirm: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('"$habitName" deleted')));
              Navigator.pop(context); 
            },
          );
        }
        break;
    }
  }

  static void _navigateToEditScreen(BuildContext context, HabitModel habit) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditHabitScreen(habit: habit)),
    );
  }

  static void _navigateToReminderSettings(
    BuildContext context,
    HabitModel habit,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReminderListScreen(habit: habit)),
    );
  }
}
