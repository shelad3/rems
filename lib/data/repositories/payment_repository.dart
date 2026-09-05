import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_model.dart';
import '../services/firebase_service.dart';

class PaymentRepository {
  final FirebaseService _firebase = FirebaseService();

  Stream<List<PaymentModel>> getPaymentsByTenant(String tenantId) {
    return _firebase.paymentsCollection
        .where('tenantId', isEqualTo: tenantId)
        .orderBy('paidAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<PaymentModel>> getPaymentsByProperty(String propertyId) {
    return _firebase.paymentsCollection
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('paidAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> recordPayment(PaymentModel payment) async {
    await _firebase.paymentsCollection.doc(payment.paymentId).set(payment.toMap());
  }

  Future<double> getTotalCollected(String propertyId, {DateTime? start, DateTime? end}) async {
    Query query = _firebase.paymentsCollection
        .where('propertyId', isEqualTo: propertyId)
        .where('status', isEqualTo: 'paid');
    if (start != null) {
      query = query.where('paidAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    }
    if (end != null) {
      query = query.where('paidAt', isLessThanOrEqualTo: Timestamp.fromDate(end));
    }
    final snapshot = await query.get();
    double total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['amount'] ?? 0).toDouble();
    }
    return total;
  }

  Future<List<PaymentModel>> getAllPayments() async {
    final snapshot = await _firebase.paymentsCollection.get();
    return snapshot.docs
        .map((doc) => PaymentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});
