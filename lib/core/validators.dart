double? parseExpenseAmount(String? value) {
  final input = value?.trim() ?? '';
  if (input.isEmpty) return null;

  late final String normalized;
  if (input.contains('.')) {
    if (_groupedWithDot.hasMatch(input)) {
      normalized = input.replaceAll(',', '');
    } else if (_plainDecimal.hasMatch(input)) {
      normalized = input;
    } else {
      return null;
    }
  } else if (_groupedInteger.hasMatch(input)) {
    normalized = input.replaceAll(',', '');
  } else if (_decimalComma.hasMatch(input)) {
    normalized = input.replaceFirst(',', '.');
  } else if (_plainInteger.hasMatch(input)) {
    normalized = input;
  } else {
    return null;
  }

  final amount = double.tryParse(normalized);
  if (amount == null || !amount.isFinite || amount <= 0 || amount > 1e9) {
    return null;
  }
  return amount;
}

String? validateExpenseAmount(String? value) {
  if (value == null || value.trim().isEmpty) return 'Enter an amount.';
  final amount = parseExpenseAmount(value);
  if (amount != null) return null;

  final normalized = value.trim().replaceAll(',', '');
  final parsed = double.tryParse(normalized);
  if (parsed != null && parsed.isFinite && parsed > 1e9) {
    return 'Amount must be no more than 1,000,000,000.';
  }
  if (parsed != null && parsed.isFinite && parsed <= 0) {
    return 'Amount must be greater than zero.';
  }
  return 'Enter a valid amount greater than zero.';
}

String? validateExpenseTitle(String? value) {
  final title = value?.trim() ?? '';
  if (title.isEmpty) return 'Enter a title.';
  if (title.length > 60) return 'Title must be 60 characters or fewer.';
  return null;
}

String? validateExpenseNote(String? value) {
  if ((value?.length ?? 0) > 200) {
    return 'Note must be 200 characters or fewer.';
  }
  return null;
}

final _groupedWithDot = RegExp(r'^[+-]?\d{1,3}(,\d{3})+\.\d+$');
final _groupedInteger = RegExp(r'^[+-]?\d{1,3}(,\d{3})+$');
final _decimalComma = RegExp(r'^[+-]?\d+,\d+$');
final _plainDecimal = RegExp(r'^[+-]?\d+\.\d+$');
final _plainInteger = RegExp(r'^[+-]?\d+$');
