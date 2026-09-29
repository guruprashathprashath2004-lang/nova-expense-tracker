import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';

class ExpenseRepository {
  ExpenseRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _expenses =>
      _firestore.collection('expenses');

  Stream<List<Expense>> watchForUser(String userId) {
    return _expenses
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final expenses = snapshot.docs.map((document) {
        final data = Map<String, dynamic>.from(document.data());
        final rawDate = data['date'];
        data['date'] = rawDate is Timestamp
            ? rawDate.toDate().toIso8601String()
            : rawDate?.toString() ?? '';
        data['id'] = document.id;
        return Expense.fromJson(data);
      }).toList()
        ..sort((left, right) => right.date.compareTo(left.date));
      return expenses;
    });
  }

  Future<void> create(Expense expense, {required String userId}) async {
    if (userId.isEmpty || expense.userId != userId) {
      throw ArgumentError('Expense owner must match the authenticated user.');
    }
    if (expense.title.trim().isEmpty || expense.amount <= 0) {
      throw ArgumentError('A title and positive amount are required.');
    }

    final reference = _expenses.doc(expense.id);
    await reference.set({
      ...expense.toJson(),
      'title': expense.title.trim(),
      'userId': userId,
      'date': Timestamp.fromDate(expense.date),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> update(Expense expense, {required String userId}) async {
    final reference = _expenses.doc(expense.id);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final existing = snapshot.data();
      if (!snapshot.exists ||
          existing == null ||
          existing['userId'] != userId) {
        throw StateError('Expense was not found for the signed-in user.');
      }
      transaction.update(reference, {
        'title': expense.title.trim(),
        'category': expense.category,
        'amount': expense.amount,
        'date': Timestamp.fromDate(expense.date),
        'note': expense.note,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> delete(String expenseId, {required String userId}) async {
    final reference = _expenses.doc(expenseId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final existing = snapshot.data();
      if (!snapshot.exists ||
          existing == null ||
          existing['userId'] != userId) {
        throw StateError('Expense was not found for the signed-in user.');
      }
      transaction.delete(reference);
    });
  }
}
