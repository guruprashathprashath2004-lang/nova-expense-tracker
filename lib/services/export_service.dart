import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/expense.dart';
import 'currency_service.dart';

class ExportService {
  const ExportService();

  Future<void> exportCsv({
    required List<Expense> expenses,
    required String currencyCode,
    required Map<String, double> rates,
  }) async {
    final rows = <List<dynamic>>[
      ['Title', 'Amount', 'Currency', 'Category', 'Date', 'Note'],
      ...expenses.map((expense) => [
            expense.title,
            CurrencyService.fromLkr(expense.amount, currencyCode, rates),
            currencyCode,
            expense.category,
            DateFormat('yyyy-MM-dd').format(expense.date),
            expense.note,
          ]),
    ];
    final bytes = Uint8List.fromList(
      utf8.encode(const ListToCsvConverter().convert(rows)),
    );
    await Share.shareXFiles([
      XFile.fromData(bytes, name: 'nova-expenses.csv', mimeType: 'text/csv'),
    ]);
  }

  Future<void> exportPdf({
    required List<Expense> expenses,
    required String currencyCode,
    required Map<String, double> rates,
  }) async {
    final report = pw.Document();
    report.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Text(
            'Nova expenses',
            style: const pw.TextStyle(
                fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.TableHelper.fromTextArray(
            headers: const ['Date', 'Title', 'Category', 'Amount'],
            data: expenses
                .map((expense) => [
                      DateFormat('yyyy-MM-dd').format(expense.date),
                      expense.title,
                      expense.category,
                      CurrencyService.format(
                        expense.amount,
                        currencyCode,
                        rates,
                      ),
                    ])
                .toList(),
          ),
        ],
      ),
    );
    await Share.shareXFiles([
      XFile.fromData(
        await report.save(),
        name: 'nova-expenses.pdf',
        mimeType: 'application/pdf',
      ),
    ]);
  }
}
