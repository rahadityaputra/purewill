
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:purewill/features/auth/services/auth_refresh_client.dart';
import 'package:purewill/features/auth/services/auth_service.dart';
import 'package:purewill/features/habit/services/habit_api_service.dart';
import 'package:purewill/features/habit/services/local_notification_service.dart';
import 'package:purewill/features/habit/services/reminder_api_service.dart';
import 'package:purewill/features/habit/models/habit_model.dart';
import 'package:purewill/features/habit/models/reminder_setting_model.dart';

class ReminderSyncService {
  static final ReminderSyncService _instance = ReminderSyncService._internal();
  factory ReminderSyncService() => _instance;
  ReminderSyncService._internal();

  final LocalNotificationService _notificationService =
      LocalNotificationService();
  late final ReminderApiService _reminderApiService;
  late final HabitApiService _habitApiService;
  late final AuthService _authService;
  late final http.Client _httpClient;

  StreamSubscription? _reminderSubscription;

  Future<void> initialize({AuthService? authService, http.Client? httpClient}) async {
    _authService = authService ?? AuthService();

    _httpClient = httpClient ?? AuthRefreshClient(
      http.Client(),
      _authService,
      onTokenRefreshed: (token) {
        _habitApiService.setAccessToken(token);
        _reminderApiService.setAccessToken(token);
      },
      onTokenExpired: () async {
        await _authService.clearSessionTokens();
      },
    );
    _reminderApiService = ReminderApiService(client: _httpClient);
    _habitApiService = HabitApiService(client: _httpClient);

    await _restoreAuthAndSyncTokens();
    Future.delayed(const Duration(milliseconds: 500), () {
      rescheduleAllReminders();
    }).ignore();
  }

  Future<void> _restoreAuthAndSyncTokens() async {
    try {
      await _authService.restoreSession(requireBiometric: true);
      final token = _authService.accessToken;
      if (token == null || token.isEmpty) {
        debugPrint('ℹ️ Reminder sync skipped: no stored auth token');
        return;
      }

      _habitApiService.setAccessToken(token);
      _reminderApiService.setAccessToken(token);
      debugPrint('🔐 Reminder sync auth restored');
    } catch (e) {
      debugPrint('⚠️ Failed to restore auth for reminder sync: $e');
    }
  }
  Future<void> rescheduleAllReminders() async {
    try {
      debugPrint('🔄 [BACKUP] Rescheduling all reminders from database...');
      await _notificationService.cancelAllNotifications();

      final token = _authService.accessToken;
      if (token == null || token.isEmpty) {
        debugPrint('ℹ️ [BACKUP] No auth token; skipping reschedule');
        return;
      }

      final habitsResponse = await _habitApiService.getUserHabits('me');
      final habitsData = habitsResponse['data'];
      final habits = <HabitModel>[];

      if (habitsData is List) {
        for (final item in habitsData) {
          if (item is Map) {
            habits.add(HabitModel.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }

      int scheduledCount = 0;
      for (final habit in habits) {
        try {
          final reminders = await _reminderApiService.getHabitReminderSettings(
            habit.id,
          );

          for (final reminderJson in reminders) {
            final reminder = ReminderSettingModel.fromJson(reminderJson);
            if (!reminder.isEnabled) continue;

            final notificationId = _buildNotificationId(
              habitId: habit.id,
              reminderId: reminder.id,
            );

            await _notificationService.scheduleHabitReminder(
              id: notificationId,
              title: 'Habit Reminder: ${habit.name}',
              body: 'Time to complete your habit: ${habit.name}',
              time: reminder.timeOfDay,
              habitId: habit.id.toString(),
              repeatDaily: reminder.repeatDaily,
            );
            scheduledCount++;
          }
        } catch (e) {
          debugPrint(
            '⚠️ [BACKUP] Failed to reschedule reminders for habit ${habit.id}: $e',
          );
        }
      }

      debugPrint(
        '✅ [BACKUP] Backup rescheduled $scheduledCount notification(s)',
      );
    } catch (e) {
      debugPrint('❌ [BACKUP] Error during backup reschedule: $e');
    }
  }

  int _buildNotificationId({required int habitId, required String reminderId}) {
    final reminderSeed = reminderId.hashCode.abs() % 10000;
    return habitId * 10000 + reminderSeed;
  }
  Future<void> dispose() async {
    await _reminderSubscription?.cancel();
    _httpClient.close();
    _authService.dispose();
    debugPrint('🛑 Reminder sync service disposed');
  }
}
