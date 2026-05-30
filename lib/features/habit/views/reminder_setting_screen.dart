import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/features/habit/services/local_notification_service.dart';
import 'package:purewill/features/habit/models/habit_model.dart';
import 'package:purewill/features/habit/services/reminder_setting_repository.dart';
import 'package:purewill/features/habit/models/reminder_setting_model.dart';
import 'package:purewill/features/auth/providers/auth_provider.dart';
import 'package:purewill/features/habit/providers/habit_provider.dart';
import '../services/reminder_setting_controller.dart';
import 'package:purewill/core/widgets/app_view_widgets.dart';

class ReminderSettingScreen extends ConsumerStatefulWidget {
  final HabitModel habit;
  final ReminderSettingModel? reminderSetting;
  const ReminderSettingScreen({
    super.key,
    required this.habit,
    this.reminderSetting,
  });
  @override
  ConsumerState<ReminderSettingScreen> createState() =>
      _ReminderSettingScreenState();
}

class _ReminderSettingScreenState extends ConsumerState<ReminderSettingScreen> {
  late ReminderSettingController _controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    final habitApiService = ref.read(habitApiServiceProvider);
    final token = ref.read(authServiceProvider).accessToken;
    if (token != null && token.isNotEmpty) {
      habitApiService.setAccessToken(token);
    }

    final reminderApi = ref.read(reminderApiServiceProvider);

    _controller = ReminderSettingController(
      habit: widget.habit,
      repository: ReminderSettingRepository(apiService: reminderApi),
      notificationService: LocalNotificationService(),
      habitApiService: habitApiService,
    )..addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveSettings() async {
    try {
      await _controller.saveSettings();
      _showSnackBar('Reminder settings saved successfully!');
    } catch (e) {
      _showSnackBar('Failed to save settings: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: ConsistentAppBar(
        title: 'Reminder Settings',
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: _controller.debugCurrentState,
            tooltip: 'Debug Current State',
          ),
          if (_controller.hasChanges && !_controller.isLoading)
            TextButton(
              onPressed: _saveSettings,
              child: const Text(
                'SAVE',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _controller.isLoading ? const AppLoadingView() : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildHeaderSection(),

          const SizedBox(height: 24),
          _buildMainSettingsSection(),

          const SizedBox(height: 24),
          _buildAdvancedSettingsSection(),

          const SizedBox(height: 32),
          _buildSaveButton(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Current Habit:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('ID: ${widget.habit.id}'),
                Text('Name: "${widget.habit.name}"'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        _buildStatusInfo(),
      ],
    );
  }

  Widget _buildStatusInfo() {
    final hasReminder =
        _controller.reminderSetting != null &&
        _controller.reminderSetting!.isEnabled;

    String statusText;
    Color statusColor;

    if (hasReminder) {
      statusText = _controller.reminderSetting!.dynamicTimeDisplay;
      statusColor = Colors.green;
    } else {
      statusText = 'No active reminder set';
      statusColor = Colors.grey;
    }

    return Card(
      color: hasReminder ? Colors.green[50] : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              hasReminder
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: hasReminder ? statusColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                statusText,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: hasReminder ? statusColor : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainSettingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Reminder Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildEnableToggle(),

            const SizedBox(height: 16),

            _buildTimePicker(),

            const SizedBox(height: 16),

            _buildSnoozeSettings(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnableToggle() {
    return Card(
      elevation: 1,
      color: Colors.grey[50],
      child: SwitchListTile(
        title: const Text(
          'Enable Reminder',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: const Text('Receive notifications for this habit'),
        value: _controller.pushNotification,
        onChanged: (value) => _controller.setPushNotification(value),
        activeThumbColor: Colors.blue,
        secondary: const Icon(Icons.notifications, color: Colors.blue),
      ),
    );
  }

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reminder Time',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.access_time, color: Colors.blue),
            title: const Text(
              'Set Time',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              _controller.getTimeString(_controller.selectedTime),
              style: const TextStyle(fontSize: 16),
            ),
            trailing: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            onTap: () => _showTimePicker(),
          ),
        ),
      ],
    );
  }

  Widget _buildSnoozeSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Snooze Duration',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'How long to wait before reminding again',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 12),

        Column(
          children: [
            for (int i = 0; i < _controller.snoozeOptions.length; i++)
              _buildSnoozeOption(i),
            _buildCustomSnoozeOption(),
          ],
        ),
      ],
    );
  }

  Widget _buildSnoozeOption(int index) {
    final isSelected =
        _controller.selectedSnoozeIndex == index &&
        !_controller.useCustomSnooze;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 1,
        color: isSelected ? Colors.blue[50] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: RadioGroup<int>(
          groupValue: _controller.useCustomSnooze
              ? null
              : _controller.selectedSnoozeIndex,
          onChanged: (value) {
            if (value != null) {
              _controller.setSnoozeOption(value);
            }
          },
          child: RadioListTile<int>(
            value: index,
            activeColor: Colors.blue,
            title: Text(
              '${_controller.snoozeOptions[index]} minutes',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue[800] : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomSnoozeOption() {
    final isSelected = _controller.useCustomSnooze;

    return Card(
      elevation: 1,
      color: isSelected ? Colors.blue[50] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioGroup<int>(
        groupValue: isSelected ? -1 : null,
        onChanged: (value) {
          if (value != null) {
            _controller.setUseCustomSnooze(true);
          }
        },
        child: RadioListTile<int>(
          value: -1,
          activeColor: Colors.blue,
          title: Row(
            children: [
              const Text(
                'Custom',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: TextEditingController(
                    text: _controller.customSnoozeMinutes.toString(),
                  ),
                  onChanged: (value) {
                    final minutes = int.tryParse(value) ?? 5;
                    _controller.setCustomSnooze(minutes);
                  },
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Minutes',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedSettingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune, size: 20, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Advanced Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildAdvancedOption(
              title: 'Repeat Daily',
              subtitle: 'Send reminder every day at the same time',
              value: _controller.repeatDaily,
              onChanged: _controller.setRepeatDaily,
              icon: Icons.repeat,
            ),

            const Divider(height: 1),

            _buildAdvancedOption(
              title: 'Sound',
              subtitle: 'Play sound with notification',
              value: _controller.soundEnabled,
              onChanged: _controller.setSoundEnabled,
              icon: Icons.volume_up,
            ),

            const Divider(height: 1),

            _buildAdvancedOption(
              title: 'Vibration',
              subtitle: 'Vibrate device with notification',
              value: _controller.vibrationEnabled,
              onChanged: _controller.setVibrationEnabled,
              icon: Icons.vibration,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOption({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.purple),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.purple,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSaveButton() {
    return Column(
      children: [
        if (_controller.hasChanges)
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have unsaved changes',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _controller.isLoading ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _controller.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Save Reminder Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _showTimePicker() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _controller.selectedTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            timePickerTheme: const TimePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null && pickedTime != _controller.selectedTime) {
      _controller.setSelectedTime(pickedTime);
      _showSnackBar('Time set to ${_controller.getTimeString(pickedTime)}');
    }
  }
}
