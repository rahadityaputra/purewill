import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/core/widgets/clean_bottom_navigation_bar.dart';
import 'package:purewill/features/habit/models/habit_model.dart';
import 'package:purewill/features/habit/widgets/habit_header.dart';
import 'package:purewill/core/widgets/progress_card.dart';
import 'package:purewill/features/home/widgets/habit_today_card_list.dart';
import 'package:purewill/features/pet_game/pet_screen.dart';
import 'package:purewill/features/user/models/user_model.dart';
import 'package:purewill/features/auth/providers/auth_provider.dart';
import 'package:purewill/features/auth/views/login_screen.dart';
import 'package:purewill/features/conversation/views/conversation_list_screen.dart';
import 'package:purewill/features/habit/providers/habit_provider.dart';
import 'package:purewill/features/habit/view_models/habit_view_model.dart';
import 'package:purewill/features/habit/views/habit_detail_screen.dart';
import 'package:purewill/features/habit/views/habit_screen.dart';
import 'package:purewill/features/nofap/views/nofap_screen.dart';
import 'package:purewill/features/habit/models/habit_log_model.dart';
import 'package:purewill/core/widgets/dialogs/app_alert_dialog.dart';
import 'package:purewill/core/widgets/dialogs/app_loading_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeNotifierProvider.notifier).initializeHome();
    });
  }

  void _onNavBarTap(int index) {
    if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HabitScreen()),
      );
    } else if (index == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const NoFapScreen()),
      );
    } else if (index == 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ConversationListScreen()),
      );
    } else if (index == 4) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PetScreen()),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeNotifierProvider);

    if (homeState.isLoadingRole || homeState.status == HabitStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<HabitModel> userHabits = homeState.todayHabits;
    final effectiveCompletionStatus = homeState.effectiveCompletionStatus;
    final UserModel? currentUser = homeState.currentUser;
    final String username = currentUser?.username ?? "user";
    final String fullName = currentUser?.fullName ?? "user";

    final completedToday = homeState.completedToday;
    final totalHabits = homeState.totalHabits;
    final progress = homeState.progress;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(homeNotifierProvider.notifier).initializeHome();
        },
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/home/bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                HabitHeader(
                  fullname: fullName,
                  username: username,
                  avatarUrl: currentUser?.avatarUrl,
                  onLogout: _performLogout,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Your Today Habits",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 16),

                        ProgressCard(
                          progress: progress,
                          completed: completedToday,
                          total: totalHabits,
                        ),

                        const SizedBox(height: 12),

                        HabitTodayCardList(
                          status: homeState.status,
                          errorMessage: homeState.errorMessage,
                          todayCompletionStatus: effectiveCompletionStatus,
                          habits: userHabits,
                          onHabitTap: _handleHabitTap,
                          onCheckboxTap: _handleCheckboxTap,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CleanBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }

  void _handleHabitTap(HabitModel habit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitDetailScreen(
          habit: habit,
          completionStatus: ref
              .read(homeNotifierProvider)
              .effectiveCompletionStatus,
        ),
      ),
    );
  }

  void _handleCheckboxTap(HabitModel habit) async {
    final previousStatus =
        ref.read(homeNotifierProvider).effectiveCompletionStatus[habit.id] ??
        LogStatus.neutral;

    try {
      await ref
          .read(homeNotifierProvider.notifier)
          .toggleHabitCompletion(habit);

      final newStatus =
          ref.read(homeNotifierProvider).effectiveCompletionStatus[habit.id] ??
          previousStatus;

      if (newStatus == LogStatus.success) {
        _showSnackBar('Habit completed successfully!');
      } else if (newStatus == LogStatus.failed) {
        _showSnackBar('Habit marked as failed.');
      } else if (newStatus == LogStatus.neutral) {
        _showSnackBar('Habit reset to neutral.');
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('di luar jangkauan') || msg.contains('out of range')) {
        showDialog(
          context: context,
          builder: (ctx) => AppAlertDialog(
            title: 'Location Out of Range',
            message: msg,
            actionLabel: 'OK',
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update habit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _performLogout() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AppLoadingDialog(),
      );

      ref.read(authNotifierProvider.notifier).logout();

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
