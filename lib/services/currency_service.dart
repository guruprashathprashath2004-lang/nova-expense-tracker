import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class CurrencyRates {
  const CurrencyRates({
    required this.rates,
    required this.updatedAt,
    required this.isOffline,
  });

  final Map<String, double> rates;
  final DateTime? updatedAt;
  final bool isOffline;
}

class CurrencyService {
  CurrencyService({
    http.Client? client,
    Future<SharedPreferences> Function()? preferencesLoader,
    DateTime Function()? clock,
  })  : _client = client ?? http.Client(),
        _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
        _clock = clock ?? DateTime.now;

  static const cacheDuration = Duration(hours: 6);
  static const ratesUrl = 'https://open.er-api.com/v6/latest/LKR';
  static const _ratesCacheKey = 'nova.currency.rates';
  static const _updatedAtCacheKey = 'nova.currency.rates.updated_at';

  static const defaultRates = <String, double>{
    'LKR': 1,
    'USD': 0.0032,
    'EUR': 0.0030,
    'GBP': 0.0025,
    'INR': 0.27,
  };

  final http.Client _client;
  final Future<SharedPreferences> Function() _preferencesLoader;
  final DateTime Function() _clock;

  static double fromLkr(
    double amount,
    String currencyCode,
    Map<String, double> rates,
  ) {
    final rate = rates[currencyCode];
    if (rate == null || !rate.isFinite || rate <= 0) {
      throw ArgumentError.value(
          currencyCode, 'currencyCode', 'Unsupported currency');
    }
    return amount * rate;
  }

  static double toLkr(
    double amount,
    String currencyCode,
    Map<String, double> rates,
  ) {
    final rate = rates[currencyCode];
    if (rate == null || !rate.isFinite || rate <= 0) {
      throw ArgumentError.value(
          currencyCode, 'currencyCode', 'Unsupported currency');
    }
    return amount / rate;
  }

  static String format(
    double amountInLkr,
    String currencyCode,
    Map<String, double> rates, {
    int decimalDigits = 2,
  }) {
    final symbol = kCurrencies[currencyCode] ?? currencyCode;
    final amount = fromLkr(amountInLkr, currencyCode, rates);
    final separator = symbol.endsWith('.') ? ' ' : '';
    return '$symbol$separator${amount.toStringAsFixed(decimalDigits)}';
  }

  Future<CurrencyRates> getRates({bool forceRefresh = false}) async {
    String? cachedRatesJson;
    DateTime? cachedAt;
    try {
      final preferences = await _preferencesLoader();
      cachedRatesJson = preferences.getString(_ratesCacheKey);
      final cachedAtMillis = preferences.getInt(_updatedAtCacheKey);
      if (cachedAtMillis != null) {
        cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMillis);
      }

      final cachedRates = _decodeRates(cachedRatesJson);
      if (!forceRefresh &&
          cachedRates != null &&
          cachedAt != null &&
          _clock().difference(cachedAt) < cacheDuration) {
        return CurrencyRates(
          rates: cachedRates,
          updatedAt: cachedAt,
          isOffline: false,
        );
      }

      final response = await _client
          .get(Uri.parse(ratesUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw http.ClientException(
          'Exchange-rate service returned HTTP ${response.statusCode}.',
        );
      }

      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic> ||
          payload['result'] != 'success' ||
          payload['base_code'] != 'LKR') {
        throw const FormatException('Invalid LKR exchange-rate response.');
      }
      final rates = _decodeRates(jsonEncode(payload['rates']));
      if (rates == null) {
        throw const FormatException('Exchange rates are missing or invalid.');
      }

      final updatedAt = _clock();
      final cachePreferences = await _preferencesLoader();
      await cachePreferences.setString(_ratesCacheKey, jsonEncode(rates));
      await cachePreferences.setInt(
        _updatedAtCacheKey,
        updatedAt.millisecondsSinceEpoch,
      );
      return CurrencyRates(
        rates: rates,
        updatedAt: updatedAt,
        isOffline: false,
      );
    } on Exception {
      final cachedRates = _decodeRates(cachedRatesJson);
      if (cachedRates != null) {
        return CurrencyRates(
          rates: cachedRates,
          updatedAt: cachedAt,
          isOffline: true,
        );
      }
      return const CurrencyRates(
        rates: defaultRates,
        updatedAt: null,
        isOffline: true,
      );
    }
  }

  Map<String, double>? _decodeRates(String? encoded) {
    if (encoded == null) return null;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) return null;
      final rates = <String, double>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is num && value.isFinite && value > 0) {
          rates[entry.key] = value.toDouble();
        }
      }
      if (rates['LKR'] != 1 || !defaultRates.keys.every(rates.containsKey)) {
        return null;
      }
      return rates;
    } on FormatException {
      return null;
    }
  }

  void dispose() => _client.close();
}
