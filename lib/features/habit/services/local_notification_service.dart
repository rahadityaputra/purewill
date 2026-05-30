import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:purewill/core/utils/indonesia_timezone.dart';
import 'dart:developer';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  Function(String?)? _onNotificationTap;

  static const String _habitChannelId = 'habit_reminders_channel';
  static const String _testChannelId = 'test_channel';

  Future<void> initialize({Function(String?)? onNotificationTap}) async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    _onNotificationTap = onNotificationTap;

    tz.initializeTimeZones();
    tz.setLocalLocation(AppTimezone.currentLocation);

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _createNotificationChannels();

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  static void _onNotificationResponse(NotificationResponse response) {
    _instance._onNotificationTap?.call(response.payload);
  }

  Future<void> _createNotificationChannels() async {
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidPlugin?.requestExactAlarmsPermission();

      if (androidPlugin != null) {
        const AndroidNotificationChannel habitChannel =
            AndroidNotificationChannel(
              _habitChannelId,
              'Habit Reminders',
              description: 'Notifications for your habit reminders',
              importance: Importance.max,
              playSound: true,

              enableVibration: true,
            );

        const AndroidNotificationChannel testChannel =
            AndroidNotificationChannel(
              _testChannelId,
              'Test Notifications',
              description: 'Channel for test notifications',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            );

        await androidPlugin.createNotificationChannel(habitChannel);
        await androidPlugin.createNotificationChannel(testChannel);
      }
    } catch (e, stackTrace) {
      log(
        'LocalNotificationService: failed to create notification channels.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> scheduleHabitReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required String habitId,
    required bool repeatDaily,
  }) async {
    try {
      final now = nowInIndonesia();
      var scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
        0,
        0,
      );

      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      final tzScheduledTime = tz.TZDateTime(
        AppTimezone.currentLocation,
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        scheduledTime.hour,
        scheduledTime.minute,
      );
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            _habitChannelId,
            'Habit Reminders',
            channelDescription: 'Notifications for your habit reminders',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        sound: 'default',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      if (repeatDaily) {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzScheduledTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'habit_$habitId',
        );
      } else {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzScheduledTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'habit_$habitId',
        );
      }

      debugPrint('✅ NOTIFICATION SCHEDULED SUCCESSFULLY');

      await _verifyScheduledNotification(id);
    } catch (e, stackTrace) {
      log(
        'LocalNotificationService: failed to schedule habit reminder.',
        error: e,
        stackTrace: stackTrace,
      );
      await showTestNotification(title.replaceFirst('Habit Reminder: ', ''));
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  Future<void> showTestNotification(String habitName) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            _testChannelId,
            'Test Notifications',
            channelDescription: 'Channel for test notifications',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        sound: 'default',
      );
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
        100000,
      );
      await _notificationsPlugin.show(
        notificationId,
        '🧪 TEST: $habitName',
        'This is a test notification sent at ${_formatTime(nowInIndonesia())}',
        notificationDetails,
        payload: 'test_$habitName',
      );
    } catch (e, stackTrace) {
      log(
        'LocalNotificationService: failed to show test notification.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e, stackTrace) {
      log(
        'LocalNotificationService: failed to cancel notification $id.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> cancelHabitNotifications(int habitId) async {
    try {
      final pending = await getPendingNotifications();

      for (final notification in pending) {
        if (notification.payload == 'habit_$habitId') {
          await cancelNotification(notification.id);
        }
      }
    } catch (e, stackTrace) {
      log(
        'LocalNotificationService: failed to cancel habit notifications for habit $habitId.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      return pending;
    } catch (e, stackTrace) {
      log(
        'LocalNotificationService: failed to read pending notifications.',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  Future<bool> checkPermissions() async {
    try {
      bool hasPermission = false;
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidPlugin?.requestExactAlarmsPermission();

      if (androidPlugin != null) {
        try {
          const AndroidNotificationDetails androidDetails =
              AndroidNotificationDetails(
                'test_channel',
                'Test Notifications',
                importance: Importance.min,
                priority: Priority.low,
              );

          const NotificationDetails notificationDetails = NotificationDetails(
            android: androidDetails,
          );

          final testId = DateTime.now().millisecondsSinceEpoch.remainder(10000);
          await _notificationsPlugin.show(
            testId,
            'Permission Test',
            'Checking if notifications work...',
            notificationDetails,
          );

          await _notificationsPlugin.cancel(testId);
          hasPermission = true;
        } catch (e, stackTrace) {
          log(
            'LocalNotificationService: Android permission test failed.',
            error: e,
            stackTrace: stackTrace,
          );
          hasPermission = false;
        }
      }

      final iOSPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iOSPlugin != null) {
        final result = await iOSPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        hasPermission = result ?? false;
      }

      return hasPermission;
    } catch (e, stackTrace) {
      log(
        'LocalNotificationService: permission check failed.',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> requestNotificationPermissions() async {
    try {
      return await checkPermissions();
    } catch (e, stackTrace) {
      log(
        'LocalNotificationService: requestNotificationPermissions failed.',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> _verifyScheduledNotification(int id) async {
    try {
      final pending = await _notificationsPlugin.pendingNotificationRequests();

      bool found = false;
      for (final notification in pending) {
        if (notification.id == id) {
          found = true;
          break;
        }
      }

      if (!found) {}
    } catch (e, stackTrace) {
      log(
        'LocalNotificationService: failed to verify scheduled notification $id.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> handleNotificationOnStartup() async {
    try {
      final notificationService = LocalNotificationService();
      final details = await notificationService._notificationsPlugin
          .getNotificationAppLaunchDetails();

      if (details?.didNotificationLaunchApp ?? false) {
        final payload = details?.notificationResponse?.payload;
        if (payload != null) {
          _instance._onNotificationTap?.call(payload);
        }
      }
    } catch (e, stackTrace) {
      log(
        'LocalNotificationService: startup notification handling failed.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void setOnNotificationTap(Function(String?) onTap) {
    _onNotificationTap = onTap;
  }
}
