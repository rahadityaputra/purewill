import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purewill/features/habit/models/habit_model.dart';
import 'package:purewill/core/utils/indonesia_timezone.dart';
import 'package:purewill/core/services/currency_conversion_service.dart';

class HabitDetailExplanationWidget extends StatefulWidget {
  final HabitModel habit;
  final Color habitColor;

  const HabitDetailExplanationWidget({
    super.key,
    required this.habit,
    required this.habitColor,
  });

  @override
  State<HabitDetailExplanationWidget> createState() =>
      _HabitDetailExplanationWidgetState();
}

class _HabitDetailExplanationWidgetState
    extends State<HabitDetailExplanationWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.habitColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.habitColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notes / description
          if (widget.habit.notes != null && widget.habit.notes!.isNotEmpty) ...[
            const Text(
              "Notes",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.habit.notes!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
          ],

          _buildDetailRow(
            label: "Frequency",
            value: _getFrequencyLabel(widget.habit.frequency),
            color: widget.habitColor,
          ),
          const SizedBox(height: 8),

          // Target value and unit
          if (widget.habit.targetValue != null &&
              widget.habit.unit != null) ...[
            _buildDetailRow(
              label: "Target",
              value: "${widget.habit.targetValue} ${widget.habit.unit}",
              color: widget.habitColor,
            ),
            const SizedBox(height: 8),
          ],

          // Value section
          if (widget.habit.value != null && widget.habit.value! > 0) ...[
            _buildDetailRow(
              label: "Value",
              value: CurrencyConversionService.formatCurrency(
                'IDR',
                widget.habit.value!.toStringAsFixed(0),
              ),
              color: widget.habitColor,
              icon: Icons.attach_money,
            ),
            const SizedBox(height: 8),
          ],

          // Location information
          if (widget.habit.isLocationLocked &&
              widget.habit.locationName != null) ...[
            _buildDetailRow(
              label: "Location",
              value: widget.habit.locationName!,
              color: widget.habitColor,
              icon: Icons.location_on,
            ),
            const SizedBox(height: 8),
            if (widget.habit.radius != null)
              _buildDetailRow(
                label: "Radius",
                value: "${widget.habit.radius} meter",
                color: widget.habitColor,
                icon: Icons.radar_outlined,
              ),
            const SizedBox(height: 8),
          ],

          _buildDetailRow(
            label: "Started",
            value: _formatDate(widget.habit.startDate),
            color: widget.habitColor,
            icon: Icons.calendar_today,
          ),

          if (_shouldShowEndDate())
            _buildDetailRow(
              label: "End",
              value: _formatDate(widget.habit.endDate!),
              color: widget.habitColor,
              icon: Icons.calendar_today,
            ),

          const SizedBox(height: 8),
          _buildDetailRow(
            label: "Duration",
            value: _calculateDaysRunning(widget.habit.startDate),
            color: widget.habitColor,
            icon: Icons.schedule,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required Color color,
    IconData? icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.end,
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
      // Fallback to English format if the locale is not initialized
      try {
        return DateFormat('dd MMMM yyyy').format(dateTime);
      } catch (e) {
        // Last resort: simple format
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
    final endDate = widget.habit.endDate;
    if (endDate == null) {
      return false;
    }

    final normalizedStart = dateOnlyInIndonesia(widget.habit.startDate);
    final normalizedEnd = dateOnlyInIndonesia(endDate);
    return normalizedEnd.isAfter(normalizedStart);
  }
}
