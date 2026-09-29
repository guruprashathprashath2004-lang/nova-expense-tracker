import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nova/services/currency_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('converts LKR to USD and EUR using the supplied rates', () {
    const rates = CurrencyService.defaultRates;
    expect(CurrencyService.fromLkr(5000, 'USD', rates), closeTo(16, 0.01));
    expect(CurrencyService.fromLkr(5000, 'EUR', rates), closeTo(15, 0.01));
  });

  test('converts LKR to each supported display currency and back', () {
    const rates = CurrencyService.defaultRates;
    for (final currency in ['USD', 'EUR', 'GBP', 'INR']) {
      final displayed = CurrencyService.fromLkr(5000, currency, rates);
      expect(
        CurrencyService.toLkr(displayed, currency, rates),
        closeTo(5000, 0.0001),
        reason: currency,
      );
    }
    expect(CurrencyService.fromLkr(5000, 'LKR', rates), 5000);
  });

  test('uses fallback rates when the exchange-rate service is unavailable',
      () async {
    SharedPreferences.setMockInitialValues({});
    final service = CurrencyService(
      client: MockClient((_) async => http.Response('unavailable', 503)),
    );
    addTearDown(service.dispose);

    final result = await service.getRates();

    expect(result.isOffline, isTrue);
    expect(result.updatedAt, isNull);
    expect(result.rates, CurrencyService.defaultRates);
  });
}
