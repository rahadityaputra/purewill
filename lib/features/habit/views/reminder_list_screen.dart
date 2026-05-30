import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/features/habit/models/habit_model.dart';
import 'package:purewill/features/habit/models/reminder_setting_model.dart';
import 'package:purewill/features/habit/services/reminder_setting_repository.dart';
import 'package:purewill/features/habit/services/local_notification_service.dart';
import 'package:purewill/features/habit/views/add_reminder_screen.dart';
import 'package:purewill/features/habit/views/update_reminder_screen.dart';
import 'package:purewill/features/habit/providers/habit_provider.dart';
import 'package:purewill/core/widgets/primary_action_button.dart';
import 'package:purewill/core/widgets/app_view_widgets.dart';

class ReminderListScreen extends ConsumerStatefulWidget {
  final HabitModel habit;
  const ReminderListScreen({super.key, required this.habit});

  @override
  ConsumerState<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends ConsumerState<ReminderListScreen> {
  late ReminderSettingRepository _repository;
  List<ReminderSettingModel> _settings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final reminderApi = ref.read(reminderApiServiceProvider);
    _repository = ReminderSettingRepository(apiService: reminderApi);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _repository.fetchReminderSettingsListByHabit(
        widget.habit.id,
      );
      _settings = settings;
    } catch (e) {
      _settings = [];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(ReminderSettingModel setting) async {
    if (setting.id.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete reminder'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final reminderId = int.tryParse(setting.id);
      if (reminderId == null) {
        throw Exception('Invalid reminder id');
      }

      await _repository.deleteReminderSetting(reminderId);
      await LocalNotificationService().cancelHabitNotifications(
        widget.habit.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reminder deleted')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ConsistentAppBar(title: 'Reminders'),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddReminderScreen(habit: widget.habit),
            ),
          );
          await _load();
        },
        child: const Icon(Icons.add),
      ),
        body: _isLoading
          ? const AppLoadingView()
          : Padding(
              padding: const EdgeInsets.all(16),
              child: _settings.isEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('No reminders yet for this habit.'),
                        const SizedBox(height: 12),
                        PrimaryActionButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddReminderScreen(habit: widget.habit),
                              ),
                            );
                            await _load();
                          },
                          text: 'Add Reminder',
                        ),
                      ],
                    )
                  : ListView.separated(
                      itemCount: _settings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final setting = _settings[index];
                        return _buildSettingCard(setting);
                      },
                    ),
            ),
    );
  }

  Widget _buildSettingCard(ReminderSettingModel setting) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Time: ${setting.formattedTime}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: setting.isEnabled,
                  onChanged: (v) async {
                    final reminderId = int.tryParse(setting.id);
                    if (reminderId == null) return;
                    await _repository.updateReminderSetting(
                      reminderSettingId: reminderId,
                      updates: {'isEnabled': v},
                    );
                    await _load();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Repeats: ${setting.repeatDaily ? 'Daily' : 'Once'}'),
            const SizedBox(height: 8),
            Text('Next: ${setting.dynamicTimeDisplay}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PrimaryActionButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UpdateReminderScreen(
                            habit: widget.habit,
                            reminderSetting: setting,
                          ),
                        ),
                      );
                      await _load();
                    },
                    text: 'Edit',
                    leadingIcon: const Icon(Icons.edit),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    borderRadius: 12,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryActionButton(
                    onPressed: () => _delete(setting),
                    text: 'Delete',
                    leadingIcon: const Icon(Icons.delete),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    borderRadius: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
