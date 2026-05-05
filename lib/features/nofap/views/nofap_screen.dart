import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/core/widgets/clean_bottom_navigation_bar.dart';
import 'package:purewill/features/conversation/views/conversation_list_screen.dart';
import 'package:purewill/features/habit/providers/habit_provider.dart';
import 'package:purewill/core/utils/indonesia_timezone.dart';
import 'package:purewill/features/habit/views/habit_screen.dart';
import 'package:purewill/features/home/views/home_screen.dart';
import 'package:purewill/features/nofap/view_models/nofap_view_model.dart';
import 'package:purewill/core/widgets/dialogs/app_alert_dialog.dart';
import 'package:purewill/core/widgets/dialogs/app_confirm_dialog.dart';

class NoFapScreen extends ConsumerStatefulWidget {
  const NoFapScreen({super.key});

  @override
  ConsumerState<NoFapScreen> createState() => _NoFapScreenState();
}

class _NoFapScreenState extends ConsumerState<NoFapScreen> {
  final int _currentIndex = 2;
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nofapNotifierProvider.notifier).loadCurrentSession();
    });
  }

  void _onNavBarTap(int index) {
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HabitScreen()),
      );
    } else if (index == 2) {
      return;
    } else if (index == 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ConversationListScreen()),
      );
    } else if (index == 4) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ConversationListScreen()),
      );
    }
  }

  void _resetStreak() {
    showDialog(
      context: context,
      builder: (context) => AppConfirmDialog(
        title: 'Reset Streak?',
        message:
            'Are you sure you want to reset your current streak? This action cannot be undone.',
        confirmLabel: 'Reset',
        confirmColor: Colors.red,
        onConfirm: () async {
          await _relapseCurrentSession('Streak reset from nofap screen');
        },
      ),
    );
  }

  void _handleHabitAction() {
    final isHabitStarted = ref.read(nofapNotifierProvider).isHabitStarted;

    if (isHabitStarted) {
      _stopHabit();
    } else {
      _startHabit();
    }
  }

  void _startHabit() {
    showDialog(
      context: context,
      builder: (context) => AppConfirmDialog(
        title: 'Start NoFap Journey?',
        message:
            'Are you ready to start your NoFap journey? This will begin tracking your progress.',
        confirmLabel: 'Start',
        confirmColor: Colors.green,
        onConfirm: () async {
          await _startCurrentSession();
        },
      ),
    );
  }

  void _stopHabit() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Relapse Occurred?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Don\'t be too hard on yourself. Every setback is a setup for a comeback.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              const Text(
                'What caused the relapse? (Optional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: 'Enter the reason...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              final finalMessage = reason.isNotEmpty
                  ? 'Relapse reported from nofap screen. Reason: $reason'
                  : 'Relapse reported from nofap screen';

              if (mounted) {
                Navigator.of(context).pop();
              }
              await _relapseCurrentSession(finalMessage);
            },
            child: const Text('Reset & Restart'),
          ),
        ],
      ),
    );
  }

  Future<void> _startCurrentSession() async {
    try {
      await ref.read(nofapNotifierProvider.notifier).startSession();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NoFap journey started! You got this!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => const AppAlertDialog(
          title: 'Session Cannot Be Started Yet',
          message:
              'The NoFap session cannot be started again right now. Please try again later.',
          actionLabel: 'OK',
        ),
      );
    }
  }

  Future<void> _relapseCurrentSession(String notes) async {
    try {
      await ref
          .read(nofapNotifierProvider.notifier)
          .stopCurrentSession(relapseNotes: notes);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'It\'s okay! Tomorrow is a fresh start. You can do this!',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update NoFap session: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nofapState = ref.watch(nofapNotifierProvider);
    final currentStreak = nofapState.currentStreak;
    final longestStreak = nofapState.longestStreak;
    final totalRelapses = nofapState.totalRelapses;
    final isHabitStarted = nofapState.isHabitStarted;
    final successDays = nofapState.successDays;

    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        title: const Text(
          'NoFap Journey',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.red),
            onPressed: isHabitStarted ? _resetStreak : null,
            tooltip: 'Reset Streak',
          ),
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/home/bg.png', fit: BoxFit.cover),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
          ),

          // Main Content
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(nofapNotifierProvider.notifier)
                    .loadCurrentSession();
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (nofapState.status == NofapStatus.failure &&
                      nofapState.errorMessage != null) ...[
                    _buildErrorCard(nofapState.errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  // Current Streak Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$currentStreak',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Days Clean',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Statistics Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Longest Streak',
                          '$longestStreak days',
                          Icons.military_tech,
                          Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Total Relapses',
                          '$totalRelapses',
                          Icons.warning,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Motivational Quote Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.format_quote,
                          size: 32,
                          color: Colors.purple,
                        ),
                        const SizedBox(height: 12),
                        if (nofapState.motivation != null) ...[
                          Text(
                            '"${nofapState.motivation!.quote}"',
                            style: const TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '— ${nofapState.motivation!.author}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.purple,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ] else
                          const Text(
                            'Loading motivation...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Benefits You\'re Experiencing',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...(nofapState.benefits
                            .map(
                              (benefit) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        benefit,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'This Month\'s Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCalendarGrid(successDays),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: CleanBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: nofapState.status == NofapStatus.loading
            ? null
            : _handleHabitAction,
        backgroundColor: isHabitStarted
            ? Colors.red.shade600
            : Colors.green.shade600,
        foregroundColor: Colors.white,
        icon: Icon(isHabitStarted ? Icons.stop : Icons.play_arrow),
        label: Text(isHabitStarted ? 'Relapse' : 'Start'),
        heroTag: "nofap_action_fab",
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(message, style: TextStyle(color: Colors.red.shade700)),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(List<DateTime> successDays) {
    final now = nowInIndonesia();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final leadingEmptyCells = firstDayOfMonth.weekday % 7;

    return Column(
      children: [
        Text(
          '${_monthName(now.month)} ${now.year}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map(
                (day) => Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: leadingEmptyCells + daysInMonth,
          itemBuilder: (context, index) {
            if (index < leadingEmptyCells) {
              return const SizedBox.shrink();
            }

            final day = index - leadingEmptyCells + 1;
            final currentDate = DateTime(now.year, now.month, day);
            final isToday = day == now.day;
            final isSuccess = successDays.any(
              (successDay) =>
                  successDay.year == currentDate.year &&
                  successDay.month == currentDate.month &&
                  successDay.day == currentDate.day,
            );

            return Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSuccess
                    ? Colors.green.shade400
                    : isToday
                    ? Colors.blue.shade200
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: isToday
                    ? Border.all(color: Colors.blue, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSuccess
                        ? Colors.white
                        : isToday
                        ? Colors.blue.shade800
                        : Colors.black87,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _monthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    if (month < 1 || month > months.length) {
      return '';
    }

    return months[month - 1];
  }
}
