import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/database_helper.dart';
import '../models/payment.dart';
import '../services/firestore_service.dart';

class PaymentProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final FirestoreService _firestore = FirestoreService.instance;
  List<Payment> _payments = [];
  List<Map<String, dynamic>> _recentPayments = [];
  double _totalCollected = 0;
  double _totalDue = 0;
  bool _isLoading = false;

  List<Payment> get payments => _payments;
  List<Map<String, dynamic>> get recentPayments => _recentPayments;
  double get totalCollected => _totalCollected;
  double get totalDue => _totalDue;
  bool get isLoading => _isLoading;

  Stream<QuerySnapshot> get paymentsStream =>
      _firestore.db.collection('payments').snapshots();

  Future<void> loadPayments() async {
    _isLoading = true;
    notifyListeners();
    final maps = await _db.queryAll('payments');
    _payments = maps.map((m) => Payment.fromMap(m)).toList();
    _totalCollected = await _db.getTotalRentCollected();
    _totalDue = await _db.getTotalRentDue();
    _recentPayments = await _db.getRecentPayments(10);
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addPayment(Payment payment,
      {String? checkoutRequestId}) async {
    final id = await _db.insert('payments', payment.toMap());
    try {
      final firestoreData = {
        ...payment.toFirestoreMap(),
        'createdAt': DateTime.now().toIso8601String(),
      };
      if (checkoutRequestId != null) {
        firestoreData['checkoutRequestId'] = checkoutRequestId;
      }
      await _firestore.db.collection('payments').add(firestoreData);
    } catch (e) {
      debugPrint('Firestore addPayment error: $e');
    }
    await loadPayments();
    return id;
  }

  Future<void> updatePayment(Payment payment) async {
    await _db.update('payments', payment.toMap(), payment.id!);
    try {
      final docs = await _firestore.db
          .collection('payments')
          .where('oldPaymentId', isEqualTo: payment.id)
          .get();
      for (final d in docs.docs) {
        await d.reference.update(payment.toFirestoreMap());
      }
    } catch (e) {
      debugPrint('Firestore updatePayment error: $e');
    }
    await loadPayments();
  }

  Future<void> deletePayment(int id) async {
    await _db.delete('payments', id);
    try {
      final docs = await _firestore.db
          .collection('payments')
          .where('oldPaymentId', isEqualTo: id)
          .get();
      for (final d in docs.docs) {
        await d.reference.delete();
      }
    } catch (e) {
      debugPrint('Firestore deletePayment error: $e');
    }
    await loadPayments();
  }

  List<Payment> getPaymentsByLease(int leaseId) {
    return _payments.where((p) => p.leaseId == leaseId).toList();
  }

  List<Payment> getPaymentsByTenant(int tenantId) {
    return _payments.where((p) => p.tenantId == tenantId).toList();
  }

  Future<List<Map<String, dynamic>>> getMonthlyRevenue(int year) async {
    return await _db.getMonthlyRevenue(year);
  }
}
