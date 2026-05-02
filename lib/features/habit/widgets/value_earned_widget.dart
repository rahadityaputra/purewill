import 'package:flutter/material.dart';
import 'package:purewill/features/habit/models/habit_model.dart';
import 'package:purewill/features/habit/models/habit_log_model.dart';
import 'package:purewill/core/services/currency_conversion_service.dart';

class ValueEarnedWidget extends StatefulWidget {
  final HabitModel habit;
  final List<HabitLogModel> habitLogs;
  final Color habitColor;

  const ValueEarnedWidget({
    super.key,
    required this.habit,
    required this.habitLogs,
    required this.habitColor,
  });

  @override
  State<ValueEarnedWidget> createState() => _ValueEarnedWidgetState();
}

class _ValueEarnedWidgetState extends State<ValueEarnedWidget> {
  // 3 currencies: IDR (default), USD, EUR
  static const List<String> displayCurrencies = ['IDR', 'USD', 'EUR'];

  late String _selectedCurrency;
  late Future<Map<String, double>> _exchangeRatesFuture;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = 'IDR';
    _exchangeRatesFuture = CurrencyConversionService.getExchangeRates();
  }

  int _getSuccessCount() {
    return widget.habitLogs
        .where((log) => log.status == LogStatus.success)
        .length;
  }

  double _calculateEarnedValue() {
    if (widget.habit.value == null || widget.habit.value! <= 0) {
      return 0;
    }
    final successCount = _getSuccessCount();
    return widget.habit.value! * successCount;
  }

  String _formatEarnedValue(double baseValue) {
    return baseValue.toStringAsFixed(0);
  }

  String _convertAndFormat(double baseValue, Map<String, double> rates) {
    if (_selectedCurrency == 'IDR') {
      return CurrencyConversionService.formatCurrency(
        'IDR',
        _formatEarnedValue(baseValue),
      );
    }

    if (rates.containsKey(_selectedCurrency)) {
      final convertedValue = baseValue * rates[_selectedCurrency]!;
      return CurrencyConversionService.formatCurrency(
        _selectedCurrency,
        convertedValue.toStringAsFixed(2),
      );
    }

    return _formatEarnedValue(baseValue);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.habit.value == null || widget.habit.value! <= 0) {
      return const SizedBox.shrink();
    }

    final earnedValue = _calculateEarnedValue();
    final successCount = _getSuccessCount();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Value Earned',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              // Currency Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.habitColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.habitColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: DropdownButton<String>(
                  value: _selectedCurrency,
                  underline: const SizedBox.shrink(),
                  items: displayCurrencies
                      .map((currency) => DropdownMenuItem(
                            value: currency,
                            child: Text(
                              currency,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: widget.habitColor,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCurrency = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, double>>(
            future: _exchangeRatesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 40,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          widget.habitColor.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Failed to load exchange rates',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade400,
                    ),
                  ),
                );
              } else if (snapshot.hasData) {
                final rates = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.habitColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.habitColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Earned',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            _convertAndFormat(earnedValue, rates),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: widget.habitColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$successCount successful${successCount == 1 ? '' : 's'} × ${CurrencyConversionService.formatCurrency('IDR', widget.habit.value!.toStringAsFixed(0))}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
