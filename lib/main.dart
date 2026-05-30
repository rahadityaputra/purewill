import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http show Client;
import 'package:purewill/core/theme/app_theme.dart';
import 'package:purewill/features/habit/services/local_notification_service.dart';
import 'package:purewill/features/habit/services/reminder_sync_service.dart';
import 'package:purewill/features/auth/services/auth_service.dart';
import 'package:purewill/features/auth/services/auth_refresh_client.dart';
import 'package:purewill/features/auth/services/auth_singleton.dart';
import 'package:purewill/features/auth/services/auth_wrapper.dart';
import 'package:purewill/features/home/views/home_screen.dart';
import 'package:purewill/features/auth/views/login_screen.dart';
import 'package:purewill/features/auth/views/signup_screen.dart';
import 'package:purewill/core/utils/indonesia_timezone.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeIndonesiaTimezone();

  await dotenv.load(fileName: ".env");

  _printApiConfig();

  await _initializeServices();

  runApp(const ProviderScope(child: MyApp()));
}

void _printApiConfig() {
  final host = dotenv.env['API_HOST'] ?? 'localhost';
  final port = dotenv.env['API_PORT'] ?? '4000';
  final baseUrl = 'http://$host:$port/api';

  debugPrint('═══════════════════════════════════════════');
  debugPrint('🌐 API Configuration:');
  debugPrint('   Host: $host');
  debugPrint('   Port: $port');
  debugPrint('   Base URL: $baseUrl');
  debugPrint('═══════════════════════════════════════════');
}

Future<void> _initializeServices() async {
  try {
    final notificationService = LocalNotificationService();
    await notificationService.initialize(
      onNotificationTap: (payload) {
        _handleNotificationPayload(payload);
      },
    );

    await LocalNotificationService.handleNotificationOnStartup();
    await _initializeReminderSyncService();

    debugPrint('✅ All services initialized successfully');
  } catch (e) {
    debugPrint('❌ Error initializing services: $e');
  }
}

void _handleNotificationPayload(String? payload) {
  if (payload == null) return;
  debugPrint('🎯 Handling general notification payload: $payload');
}

Future<void> _initializeReminderSyncService() async {
  bool syncInitialized = false;
  int retryCount = 0;
  const maxRetries = 3;

  final sharedAuth = AuthService();
  final sharedClient = AuthRefreshClient(
    http.Client(),
    sharedAuth,
    onTokenExpired: () async {
      await sharedAuth.clearSessionTokens();
    },
  );

  sharedAuthService = sharedAuth;
  sharedHttpClient = sharedClient;

  while (!syncInitialized && retryCount < maxRetries) {
    try {
      await ReminderSyncService().initialize(
        authService: sharedAuth,
        httpClient: sharedClient,
      );
      syncInitialized = true;
      debugPrint('✅ ReminderSyncService initialized successfully');
    } catch (e) {
      retryCount++;
      debugPrint(
        '⚠️ ReminderSyncService initialization attempt $retryCount failed: $e',
      );
      if (retryCount < maxRetries) {
        await Future.delayed(const Duration(seconds: 2));
      } else {
        debugPrint(
          '❌ ReminderSyncService initialization failed after $maxRetries attempts',
        );
      }
    }
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'PureWill',
      theme: AppTheme.light(),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/signup': (context) => const SignupScreen(),
        '/logout': (context) => const LoginScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
