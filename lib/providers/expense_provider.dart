import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../services/firestore_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService.instance;
  List<Expense> _expenses = [];
  bool _isLoading = false;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> get categoryTotals {
    final totals = <String, double>{};
    for (final e in _expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals.entries.map((e) => {
      'category': e.key,
      'total': e.value,
    }).toList();
  }

  Map<String, dynamic> get summary {
    double total = 0;
    for (final e in _expenses) {
      total += e.amount;
    }
    return {
      'total_expenses': total,
      'expense_count': _expenses.length,
    };
  }

  Future<void> loadExpensesByProperty(int propertyId) async {
    _isLoading = true;
    notifyListeners();
    final snapshot = await _firestore.db
        .collection('expenses')
        .where('propertyId', isEqualTo: propertyId)
        .get();
    _expenses = snapshot.docs
        .map((doc) =>
            Expense.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAllExpenses() async {
    _isLoading = true;
    notifyListeners();
    final snapshot = await _firestore.db.collection('expenses').get();
    _expenses = snapshot.docs
        .map((doc) =>
            Expense.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    _isLoading = false;
    notifyListeners();
  }

  List<Expense> searchExpenses(String query) {
    final q = query.toLowerCase();
    return _expenses.where((e) =>
      e.title.toLowerCase().contains(q) ||
      e.category.toLowerCase().contains(q) ||
      e.description.toLowerCase().contains(q)
    ).toList();
  }

  Future<void> addExpense(Expense expense) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    await _firestore.db.collection('expenses').doc(id.toString()).set(
      expense.toFirestoreMap(),
    );
    await loadAllExpenses();
  }

  Future<void> updateExpense(Expense expense) async {
    await _firestore.db
        .collection('expenses')
        .doc(expense.id!.toString())
        .update(expense.toFirestoreMap());
    await loadAllExpenses();
  }

  Future<void> deleteExpense(int id) async {
    await _firestore.db.collection('expenses').doc(id.toString()).delete();
    await loadAllExpenses();
  }

  Map<String, dynamic> getProfitLoss(int propertyId) {
    final propExpenses = _expenses.where((e) => e.propertyId == propertyId);
    double total = 0;
    for (final e in propExpenses) {
      total += e.amount;
    }
    return {
      'total_expenses': total,
      'expense_count': propExpenses.length,
    };
  }

  double getTotalExpenses() {
    return (summary['total_expenses'] as num?)?.toDouble() ?? 0;
  }

  int getExpenseCount() {
    return (summary['expense_count'] as int?) ?? 0;
  }
}
