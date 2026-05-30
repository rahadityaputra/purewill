import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purewill/features/habit/models/habit_model.dart';
import 'package:purewill/core/services/currency_conversion_service.dart';
import 'package:purewill/core/utils/indonesia_timezone.dart';

class HabitDetailExplanationWidget extends StatelessWidget {
  final HabitModel habit;
  final Color habitColor;

  const HabitDetailExplanationWidget({
    super.key,
    required this.habit,
    required this.habitColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (habit.notes != null && habit.notes!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: habitColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: habitColor.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      habit.notes!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            _buildDetailRow(
              label: 'Frequency',
              value: _getFrequencyLabel(habit.frequency),
              color: habitColor,
            ),
            if (habit.targetValue != null && habit.unit != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              _buildDetailRow(
                label: 'Target',
                value: '${habit.targetValue} ${habit.unit}',
                color: habitColor,
              ),
            ],
            if (habit.value != null && habit.value! > 0) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              _buildDetailRow(
                label: 'Value',
                value: CurrencyConversionService.formatCurrency(
                  'IDR',
                  habit.value!.toStringAsFixed(0),
                ),
                color: habitColor,
                icon: Icons.attach_money,
              ),
            ],
            if (habit.isLocationLocked && habit.locationName != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              _buildDetailRow(
                label: 'Location',
                value: habit.locationName!,
                color: habitColor,
                icon: Icons.location_on,
              ),
              if (habit.radius != null) ...[
                const SizedBox(height: 10),
                _buildDetailRow(
                  label: 'Radius',
                  value: '${habit.radius} meter',
                  color: habitColor,
                  icon: Icons.radar_outlined,
                ),
              ],
            ],
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _buildDetailRow(
              label: 'Started',
              value: _formatDate(habit.startDate),
              color: habitColor,
              icon: Icons.calendar_today,
            ),
            if (_shouldShowEndDate()) ...[
              const SizedBox(height: 10),
              _buildDetailRow(
                label: 'End',
                value: _formatDate(habit.endDate!),
                color: habitColor,
                icon: Icons.calendar_today,
              ),
            ],
            const SizedBox(height: 10),
            _buildDetailRow(
              label: 'Duration',
              value: _calculateDaysRunning(habit.startDate),
              color: habitColor,
              icon: Icons.schedule,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required Color color,
    IconData? icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                  height: 1.35,
                ),
                textAlign: TextAlign.start,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getFrequencyLabel(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return 'Every day';
      case 'weekly':
        return 'Every week';
      case 'monthly':
        return 'Every month';
      case 'custom':
        return 'Custom';
      default:
        return frequency;
    }
  }

  String _formatDate(DateTime dateTime) {
    try {
      return DateFormat('dd MMMM yyyy', 'en_US').format(dateTime);
    } catch (e) {
      try {
        return DateFormat('dd MMMM yyyy').format(dateTime);
      } catch (e) {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    }
  }

  String _calculateDaysRunning(DateTime startDate) {
    final now = nowInIndonesia();
    final difference = now.difference(startDate).inDays + 1;
    return '$difference days';
  }

  bool _shouldShowEndDate() {
    final endDate = habit.endDate;
    if (endDate == null) {
      return false;
    }

    final normalizedStart = dateOnlyInIndonesia(habit.startDate);
    final normalizedEnd = dateOnlyInIndonesia(endDate);
    return normalizedEnd.isAfter(normalizedStart);
  }
}
