import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyConversionService {
  static const String baseUrl = 'https://api.exchangerate-api.com/v4/latest';

  static const List<String> supportedCurrencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'AUD',
    'CAD',
    'SGD',
    'INR',
    'MYR',
    'THB',
  ];

  static const String baseCurrency = 'IDR';

  static Future<Map<String, double>> getExchangeRates() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/$baseCurrency'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = Map<String, double>.from(
          (data['rates'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ),
        );

        final filteredRates = <String, double>{};
        for (final currency in supportedCurrencies) {
          if (rates.containsKey(currency)) {
            filteredRates[currency] = rates[currency]!;
          }
        }

        return filteredRates;
      } else {
        throw Exception(
          'Failed to fetch exchange rates: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, String>> convertIDRToMultipleCurrencies(
    double idrAmount,
  ) async {
    final rates = await getExchangeRates();
    final conversions = <String, String>{};

    for (final currency in supportedCurrencies) {
      if (rates.containsKey(currency)) {
        final convertedAmount = idrAmount * rates[currency]!;
        conversions[currency] = convertedAmount.toStringAsFixed(2);
      }
    }

    return conversions;
  }

  static String formatCurrency(String currencyCode, String amount) {
    final symbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'AUD': 'A\$',
      'CAD': 'C\$',
      'SGD': 'S\$',
      'INR': '₹',
      'MYR': 'RM',
      'THB': '฿',
      'IDR': 'Rp',
    };

    final symbol = symbols[currencyCode] ?? currencyCode;
    return '$symbol $amount';
  }

  static String getCurrencyName(String currencyCode) {
    const names = {
      'USD': 'US Dollar',
      'EUR': 'Euro',
      'GBP': 'British Pound',
      'JPY': 'Japanese Yen',
      'AUD': 'Australian Dollar',
      'CAD': 'Canadian Dollar',
      'SGD': 'Singapore Dollar',
      'INR': 'Indian Rupee',
      'MYR': 'Malaysian Ringgit',
      'THB': 'Thai Baht',
      'IDR': 'Indonesian Rupiah',
    };

    return names[currencyCode] ?? currencyCode;
  }
}
