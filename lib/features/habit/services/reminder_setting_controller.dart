import 'package:flutter/material.dart';
import 'package:purewill/features/habit/services/local_notification_service.dart';
import 'package:purewill/features/habit/services/habit_api_service.dart';
import 'package:purewill/features/habit/models/habit_model.dart';
import 'package:purewill/features/habit/models/reminder_setting_model.dart';
import 'package:purewill/features/habit/services/reminder_setting_repository.dart';
import 'package:purewill/core/utils/indonesia_timezone.dart';

class ReminderSettingController with ChangeNotifier {
  final HabitModel habit;
  final ReminderSettingRepository _repository;
  final LocalNotificationService _notificationService;
  final HabitApiService _habitApiService;

  ReminderSettingModel? _reminderSetting;
  bool _isLoading = true;
  bool _hasChanges = false;
  final List<int> _snoozeOptions = [5, 10, 15, 30, 60];
  int _selectedSnoozeIndex = 1;
  int _customSnoozeMinutes = 5;
  bool _useCustomSnooze = false;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _pushNotification = true;
  bool _repeatDaily = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  ReminderSettingController({
    required this.habit,
    required ReminderSettingRepository repository,
    required LocalNotificationService notificationService,
    required HabitApiService habitApiService,
  }) : _repository = repository,
       _notificationService = notificationService,
       _habitApiService = habitApiService {
    _initialize();
  }
  bool get isLoading => _isLoading;
  bool get hasChanges => _hasChanges;
  List<int> get snoozeOptions => _snoozeOptions;
  int get selectedSnoozeIndex => _selectedSnoozeIndex;
  int get customSnoozeMinutes => _customSnoozeMinutes;
  bool get useCustomSnooze => _useCustomSnooze;
  TimeOfDay get selectedTime => _selectedTime;
  bool get pushNotification => _pushNotification;
  bool get repeatDaily => _repeatDaily;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  ReminderSettingModel? get reminderSetting => _reminderSetting;

  Future<void> _initialize() async {
    await _loadReminderSettings();
  }

  Future<void> _loadReminderSettings() async {
    try {
      final settings = await _repository.fetchReminderSettingsByHabit(habit.id);

      if (settings.isEmpty == false) {
        _reminderSetting = settings;
        _initializeFormFromModel(_reminderSetting!);
      } else {
        _reminderSetting = ReminderSettingModel.empty(habitId: habit.id);
        _initializeFormFromModel(_reminderSetting!);
      }
    } catch (e) {
      debugPrint(
        'ReminderSettingController: failed to load reminder settings for habit ${habit.id}: $e',
      );
      _reminderSetting = ReminderSettingModel.empty(habitId: habit.id);
      _initializeFormFromModel(_reminderSetting!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _initializeFormFromModel(ReminderSettingModel model) {
    _pushNotification = model.isEnabled;

    final snoozeIndex = _snoozeOptions.indexOf(model.snoozeDuration);
    if (snoozeIndex != -1) {
      _selectedSnoozeIndex = snoozeIndex;
      _useCustomSnooze = false;
    } else {
      _useCustomSnooze = true;
      _customSnoozeMinutes = model.snoozeDuration;
    }

    _selectedTime = TimeOfDay.fromDateTime(model.time);
    _repeatDaily = model.repeatDaily;
    _soundEnabled = model.isSoundEnabled;
    _vibrationEnabled = model.isVibrationEnabled;
  }

  void setSelectedTime(TimeOfDay time) {
    final now = TimeOfDay.now();
    if (time.hour < now.hour ||
        (time.hour == now.hour && time.minute <= now.minute)) {}

    _selectedTime = time;
    _hasChanges = true;
    notifyListeners();
  }

  void setPushNotification(bool value) {
    _pushNotification = value;
    _hasChanges = true;
    notifyListeners();
  }

  void setRepeatDaily(bool value) {
    _repeatDaily = value;
    _hasChanges = true;
    notifyListeners();
  }

  void setSoundEnabled(bool value) {
    _soundEnabled = value;
    _hasChanges = true;
    notifyListeners();
  }

  void setVibrationEnabled(bool value) {
    _vibrationEnabled = value;
    _hasChanges = true;
    notifyListeners();
  }

  void setSnoozeOption(int index) {
    _selectedSnoozeIndex = index;
    _useCustomSnooze = false;
    _hasChanges = true;
    notifyListeners();
  }

  void setCustomSnooze(int minutes) {
    _customSnoozeMinutes = minutes.clamp(1, 120);
    _useCustomSnooze = true;
    _hasChanges = true;
    notifyListeners();
  }

  void setUseCustomSnooze(bool value) {
    _useCustomSnooze = value;
    _hasChanges = true;
    notifyListeners();
  }

  Future<void> saveSettings() async {
    if (habit.id <= 0) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final snoozeDuration = _useCustomSnooze
          ? _customSnoozeMinutes
          : _snoozeOptions[_selectedSnoozeIndex];
      final now = nowInIndonesia();
      final scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      await _updateHabitReminderSettings(_pushNotification);

      if (_reminderSetting != null && _reminderSetting!.id.isNotEmpty) {
        final reminderId = int.tryParse(_reminderSetting!.id);
        if (reminderId != null) {
          await _repository.updateReminderSetting(
            reminderSettingId: reminderId,
            updates: {
              'time': scheduledDateTime.toIso8601String(),
              'isEnabled': _pushNotification,
              'snoozeDuration': snoozeDuration,
              'repeatDaily': _repeatDaily,
              'isSoundEnabled': _soundEnabled,
              'isVibrationEnabled': _vibrationEnabled,
            },
          );
        } else {
          final newReminder = ReminderSettingModel(
            id: '',
            habitId: habit.id,
            isEnabled: _pushNotification,
            time: scheduledDateTime,
            snoozeDuration: snoozeDuration,
            repeatDaily: _repeatDaily,
            isSoundEnabled: _soundEnabled,
            isVibrationEnabled: _vibrationEnabled,
            createdAt: nowInIndonesia(),
          );

          _reminderSetting = await _repository.createReminderSetting(
            newReminder,
          );
        }
      } else {
        final newReminder = ReminderSettingModel(
          id: '',
          habitId: habit.id,
          isEnabled: _pushNotification,
          time: scheduledDateTime,
          snoozeDuration: snoozeDuration,
          repeatDaily: _repeatDaily,
          isSoundEnabled: _soundEnabled,
          isVibrationEnabled: _vibrationEnabled,
          createdAt: nowInIndonesia(),
        );

        _reminderSetting = await _repository.createReminderSetting(newReminder);
      }
      if (_pushNotification) {
        await _scheduleNotification();
      } else {
        await _notificationService.cancelHabitNotifications(habit.id);
      }

      _hasChanges = false;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _updateHabitReminderSettings(bool reminderEnabled) async {
    final timeString =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00';

    try {
      await _habitApiService.updateHabit(habit.id, {
        'reminderEnabled': reminderEnabled,
        'reminderTime': timeString,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _scheduleNotification() async {
    try {
      await _notificationService.cancelHabitNotifications(habit.id);
      final hasPermission = await _notificationService.checkPermissions();
      if (!hasPermission) {
        return;
      }
      final notificationId = _generateNotificationId();
      await _notificationService.scheduleHabitReminder(
        id: notificationId,
        title: 'Habit Reminder: ${habit.name}',
        body: 'Time to complete your habit: ${habit.name}',
        time: _selectedTime,
        habitId: habit.id.toString(),
        repeatDaily: _repeatDaily,
      );
    } catch (e) {
      await _notificationService.showTestNotification(habit.name);
    }
  }

  int _generateNotificationId() {
    return (habit.id * 10000) +
        (_selectedTime.hour * 100 + _selectedTime.minute);
  }

  Future<void> testNotification() async {
    try {
      await _notificationService.showTestNotification(habit.name);
    } catch (e) {
      debugPrint(
        'ReminderSettingController: failed to test notification for habit ${habit.id}: $e',
      );
    }
  }

  Future<void> checkPendingNotifications() async {
    try {
      final pending = await _notificationService.getPendingNotifications();

      int ourNotifications = 0;
      for (final notification in pending) {
        if (notification.payload?.contains('habit_${habit.id}') == true) {
          ourNotifications++;
        }
      }

      if (ourNotifications == 0) {
      } else {}
    } catch (e) {
      debugPrint(
        'ReminderSettingController: failed to inspect pending notifications for habit ${habit.id}: $e',
      );
    }
  }

  Future<void> checkPermissions() async {
    try {
      await _notificationService.checkPermissions();
    } catch (e) {
      debugPrint(
        'ReminderSettingController: failed to check permissions for habit ${habit.id}: $e',
      );
    }
  }

  Future<void> resetReminderData() async {
    try {
      await _repository.deleteAllReminderSettingsForHabit(habit.id);

      await _habitApiService.updateHabit(habit.id, {
        'reminderEnabled': false,
        'reminderTime': null,
      });

      await _notificationService.cancelHabitNotifications(habit.id);

      _reminderSetting = ReminderSettingModel.empty(habitId: habit.id);
      _initializeFormFromModel(_reminderSetting!);
    } catch (e) {
      debugPrint(
        'ReminderSettingController: failed to reset reminder data for habit ${habit.id}: $e',
      );
    }
  }

  String getTimeString(TimeOfDay time) {
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final displayHour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

    return '$displayHour:$minute $period';
  }

  void debugCurrentState() {}
}
