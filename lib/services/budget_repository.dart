import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget.dart';

class BudgetRepository {
  BudgetRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _budgets =>
      _firestore.collection('budgets');

  Stream<List<Budget>> watchForUser(String userId) {
    return _budgets.where('userId', isEqualTo: userId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((document) => Budget.fromJson(document.id, document.data()))
              .toList()
            ..sort((left, right) => left.category.compareTo(right.category)),
        );
  }

  Future<void> save(Budget budget, {required String userId}) async {
    if (userId.isEmpty || budget.category.trim().isEmpty || budget.limit <= 0) {
      throw ArgumentError('A category and positive budget limit are required.');
    }
    final reference =
        budget.id.isEmpty ? _budgets.doc() : _budgets.doc(budget.id);
    await reference.set({
      ...budget.toJson(),
      'userId': userId,
      'category': budget.category.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (budget.id.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> delete(String id, {required String userId}) async {
    final reference = _budgets.doc(id);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists || snapshot.data()?['userId'] != userId) {
        throw StateError('Budget was not found for the signed-in user.');
      }
      transaction.delete(reference);
    });
  }
}
