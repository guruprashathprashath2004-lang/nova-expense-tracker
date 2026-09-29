import 'package:flutter_test/flutter_test.dart';
import 'package:nova/core/validators.dart';

void main() {
  group('parseExpenseAmount', () {
    test('parses trimmed decimal input', () {
      expect(parseExpenseAmount(' 125.50 '), 125.5);
    });

    test('accepts grouped thousands and decimal separators', () {
      expect(parseExpenseAmount('1,234'), 1234);
      expect(parseExpenseAmount('1,234,567'), 1234567);
      expect(parseExpenseAmount('1,234.56'), 1234.56);
    });

    test('accepts comma as a decimal separator when there is no dot', () {
      expect(parseExpenseAmount('12,34'), 12.34);
      expect(parseExpenseAmount('1234,5'), 1234.5);
    });

    test(
        'rejects empty, malformed, non-positive, non-finite, and excessive values',
        () {
      for (final value in [
        '',
        ' ',
        'abc',
        '1,23.45',
        '0',
        '-1',
        'NaN',
        'Infinity',
        '1,000,000,000.01',
      ]) {
        expect(parseExpenseAmount(value), isNull, reason: value);
      }
    });
  });

  group('expense field validation', () {
    test('validates required title and its maximum length', () {
      expect(validateExpenseTitle('  Lunch  '), isNull);
      expect(validateExpenseTitle('  '), 'Enter a title.');
      expect(validateExpenseTitle('x' * 61),
          'Title must be 60 characters or fewer.');
    });

    test('validates optional note length', () {
      expect(validateExpenseNote(null), isNull);
      expect(validateExpenseNote(''), isNull);
      expect(validateExpenseNote('x' * 200), isNull);
      expect(validateExpenseNote('x' * 201),
          'Note must be 200 characters or fewer.');
    });

    test('returns clear amount validation messages', () {
      expect(validateExpenseAmount(''), 'Enter an amount.');
      expect(validateExpenseAmount('0'), 'Amount must be greater than zero.');
      expect(validateExpenseAmount('1,000,000,001'),
          'Amount must be no more than 1,000,000,000.');
      expect(validateExpenseAmount('12,34'), isNull);
    });
  });
}
