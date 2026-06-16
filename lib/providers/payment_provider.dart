import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment.dart';
import '../services/firestore_service.dart';

class PaymentProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService.instance;
  List<Payment> _payments = [];
  bool _isLoading = false;

  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;

  double get totalCollected => _payments
      .where((p) => p.status == 'Paid')
      .fold(0, (sum, p) => sum + p.amount);

  double get totalDue => _payments
      .where((p) => p.status == 'Pending' || p.status == 'Overdue')
      .fold(0, (sum, p) => sum + p.amount);

  List<Map<String, dynamic>> get recentPayments {
    final sorted = List<Payment>.from(_payments)
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    return sorted.take(10).map((p) => {
      'id': p.id,
      'tenant_id': p.tenantId,
      'amount': p.amount,
      'payment_date': p.paymentDate.toIso8601String(),
      'status': p.status,
    }).toList();
  }

  Stream<QuerySnapshot> get paymentsStream =>
      _firestore.db.collection('payments').snapshots();

  Future<void> loadPayments() async {
    _isLoading = true;
    notifyListeners();
    final snapshot = await _firestore.db.collection('payments').get();
    _payments = snapshot.docs
        .map((doc) =>
            Payment.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addPayment(Payment payment,
      {String? checkoutRequestId}) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    final firestoreData = {
      ...payment.toFirestoreMap(),
      'createdAt': DateTime.now().toIso8601String(),
    };
    if (checkoutRequestId != null) {
      firestoreData['checkoutRequestId'] = checkoutRequestId;
    }
    await _firestore.db.collection('payments').doc(id.toString()).set(
      firestoreData,
    );
    await loadPayments();
    return id;
  }

  Future<void> updatePayment(Payment payment) async {
    await _firestore.db
        .collection('payments')
        .doc(payment.id!.toString())
        .update(payment.toFirestoreMap());
    await loadPayments();
  }

  Future<void> deletePayment(int id) async {
    await _firestore.db.collection('payments').doc(id.toString()).delete();
    await loadPayments();
  }

  List<Payment> getPaymentsByLease(int leaseId) {
    return _payments.where((p) => p.leaseId == leaseId).toList();
  }

  List<Payment> getPaymentsByTenant(int tenantId) {
    return _payments.where((p) => p.tenantId == tenantId).toList();
  }

  List<Map<String, dynamic>> getMonthlyRevenue(int year) {
    final monthly = <String, double>{};
    for (int m = 1; m <= 12; m++) {
      monthly[m.toString().padLeft(2, '0')] = 0;
    }
    for (final p in _payments.where((p) => p.status == 'Paid')) {
      if (p.paymentDate.year == year) {
        final key = p.paymentDate.month.toString().padLeft(2, '0');
        monthly[key] = (monthly[key] ?? 0) + p.amount;
      }
    }
    return monthly.entries.map((e) => {
      'month': int.parse(e.key),
      'total': e.value,
    }).toList();
  }
}
