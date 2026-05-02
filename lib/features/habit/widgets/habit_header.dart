import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:purewill/core/utils/indonesia_timezone.dart';
import 'package:purewill/features/user/providers/timezone_provider.dart';
import 'package:purewill/features/user/views/profile_screen.dart';

class HabitHeader extends ConsumerStatefulWidget {
  final String username;
  final String fullname;
  final String? avatarUrl;
  final VoidCallback onLogout;

  const HabitHeader({
    super.key,
    required this.username,
    required this.fullname,
    required this.onLogout,
    this.avatarUrl,
  });

  @override
  ConsumerState<HabitHeader> createState() => _HabitHeaderState();
}

class _HabitHeaderState extends ConsumerState<HabitHeader> {
  late Timer _clockTimer;
  DateTime _now = nowInIndonesia();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = nowInIndonesia();
      });
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  String _formatDateTime(DateTime dateTime, AppTimezoneOption option) {
    final dateLabel = DateFormat('EEE, dd MMM yyyy', 'en_US').format(dateTime);
    final timeLabel = DateFormat('HH:mm:ss').format(dateTime);
    return '$dateLabel • $timeLabel ${option.label}';
  }

  @override
  Widget build(BuildContext context) {
    final timezoneState = ref.watch(timezoneProvider);
    final selectedTimezone = timezoneState.selectedTimezone;
    final displayNow = _now;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(176, 230, 216, 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _ProfileAvatar(
              fullname: widget.fullname,
              avatarUrl: widget.avatarUrl,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${widget.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.fullname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(displayNow, selectedTimezone),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String fullname;
  final String? avatarUrl;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.fullname,
    required this.onTap,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(fullname);
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[200],
          backgroundImage: hasImage ? NetworkImage(avatarUrl!) : null,
          onBackgroundImageError: hasImage
              ? (exception, stackTrace) => print('Error loading avatar')
              : null,
          child: !hasImage
              ? Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7C3AED),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  String _initials(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return '?';
    final parts = cleaned
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}
