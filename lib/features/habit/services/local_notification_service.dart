import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:purewill/core/utils/indonesia_timezone.dart';

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

  // Create notification channels untuk Android
  Future<void> _createNotificationChannels() async {
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidPlugin?.requestExactAlarmsPermission();

      if (androidPlugin != null) {
        // Main habit reminders channel
        const AndroidNotificationChannel habitChannel =
            AndroidNotificationChannel(
              _habitChannelId,
              'Habit Reminders',
              description: 'Notifications for your habit reminders',
              importance: Importance.max,
              playSound: true,

              enableVibration: true,
            );

        // Test channel
        const AndroidNotificationChannel testChannel =
            AndroidNotificationChannel(
              _testChannelId,
              'Test Notifications',
              description: 'Channel for test notifications',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            );

        // Create channels
        await androidPlugin.createNotificationChannel(habitChannel);
        await androidPlugin.createNotificationChannel(testChannel);

        // debugPrint('📱 Notification channels created successfully');
      }
    } catch (e) {
      // debugPrint('❌ Error creating notification channels: $e');
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
        0, // seconds
        0, // milliseconds
      );

      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
        // debugPrint('   ⏰ Time passed today, scheduling for TOMORROW');
      } else {
        // debugPrint('   ⏰ Time is in the future, scheduling for TODAY');
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

      // Immediate verification
      await _verifyScheduledNotification(id);
    } catch (e) {
      await showTestNotification(title.replaceFirst('Habit Reminder: ', ''));
    }
  }

  // Helper method untuk format time
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

      // debugPrint('✅ TEST NOTIFICATION SENT SUCCESSFULLY');
    } catch (e) {
      // debugPrint('❌ ERROR showing test notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      // debugPrint('✅ Notification $id cancelled');
    } catch (e) {
      // debugPrint('❌ Error cancelling notification $id: $e');
    }
  }

  // Cancel all notifications for a habit
  Future<void> cancelHabitNotifications(int habitId) async {
    try {
      final pending = await getPendingNotifications();

      for (final notification in pending) {
        if (notification.payload == 'habit_$habitId') {
          await cancelNotification(notification.id);
        }
      }

      // debugPrint('✅ Cancelled $cancelledCount notifications for habit $habitId');
    } catch (e) {
      // debugPrint('❌ Error cancelling habit notifications: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      return pending;
    } catch (e) {
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
          // debugPrint('   ✅ Android: Notifications are working');
        } catch (e) {
          // debugPrint('   ❌ Android: Notifications blocked - $e');
          hasPermission = false;
        }
      }

      // Check iOS
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
        // debugPrint('   - iOS permission granted: $hasPermission');
      }

      return hasPermission;
    } catch (e) {
      // debugPrint('❌ Error checking permissions: $e');
      return false;
    }
  }

  // Request permissions
  Future<bool> requestNotificationPermissions() async {
    try {
      return await checkPermissions();
    } catch (e) {
      // debugPrint('❌ Error requesting permissions: $e');
      return false;
    }
  }

  // Verify scheduled notification dengan detail
  Future<void> _verifyScheduledNotification(int id) async {
    try {
      // debugPrint('🔍 VERIFYING SCHEDULED NOTIFICATION: $id');

      final pending = await _notificationsPlugin.pendingNotificationRequests();
      // debugPrint('   - Total pending notifications: ${pending.length}');

      bool found = false;
      for (final notification in pending) {
        // debugPrint('   - Pending: ID=${notification.id}, Title="${notification.title}", Time=${notification.body}');
        if (notification.id == id) {
          found = true;
          break;
        }
      }

      if (!found) {
        // debugPrint('   ❌ OUR NOTIFICATION NOT FOUND IN PENDING LIST!');
        // debugPrint('   This means the scheduling failed silently');
      }
    } catch (e) {
      // debugPrint('❌ Error verifying scheduled notification: $e');
    }
  }

  // Handle notification on app startup
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
    } catch (e) {
      // debugPrint('❌ Error handling notification on startup: $e');
    }
  }

  void setOnNotificationTap(Function(String?) onTap) {
    _onNotificationTap = onTap;
  }
}
