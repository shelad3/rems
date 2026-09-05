import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rent_invoice_model.dart';
import '../services/firebase_service.dart';

class RentInvoiceRepository {
  final FirebaseService _firebase = FirebaseService();

  CollectionReference get _collection => _firebase.firestore.collection('rent_invoices');

  Stream<List<RentInvoiceModel>> getInvoicesByTenant(String tenantId) {
    return _collection
        .where('tenantId', isEqualTo: tenantId)
        .orderBy('periodStart', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentInvoiceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<RentInvoiceModel>> getInvoicesByProperty(String propertyId) {
    return _collection
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('periodStart', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentInvoiceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  String invoiceIdFor(String unitId, String periodKey) => '${unitId}_$periodKey';

  Future<void> ensureInvoiceForMonth({
    required String tenantId,
    required String propertyId,
    required String unitId,
    required double amount,
    DateTime? periodStart,
  }) async {
    final start = periodStart ?? _monthStart(DateTime.now());
    final periodKey = _periodKey(start);
    final snapshot = await _collection
        .where('unitId', isEqualTo: unitId)
        .get();
    final exists = snapshot.docs.any(
        (doc) => (doc.data() as Map<String, dynamic>)['periodKey'] == periodKey);
    if (exists) return;

    final invoice = RentInvoiceModel(
      invoiceId: invoiceIdFor(unitId, periodKey),
      tenantId: tenantId,
      propertyId: propertyId,
      unitId: unitId,
      periodStart: start,
      periodKey: periodKey,
      amount: amount,
    );
    await _collection.doc(invoice.invoiceId).set(invoice.toMap());
  }

  Future<void> applyPaymentToInvoices({
    required String unitId,
    required double amount,
  }) async {
    if (amount <= 0) return;
    final now = DateTime.now();
    final snapshot = await _collection.where('unitId', isEqualTo: unitId).get();
    final unpaid = snapshot.docs
        .map((doc) => RentInvoiceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where((inv) => !inv.isPaid)
        .toList()
      ..sort((a, b) => a.periodStart.compareTo(b.periodStart));

    var remaining = amount;
    for (final invoice in unpaid) {
      if (remaining <= 0) break;
      final take = invoice.outstanding < remaining ? invoice.outstanding : remaining;
      if (take <= 0) continue;
      final newPaid = invoice.amountPaid + take;
      final nowPaid = newPaid >= invoice.amount;
      await _collection.doc(invoice.invoiceId).update({
        'amountPaid': newPaid,
        'status': nowPaid ? 'paid' : 'unpaid',
        'paidAt': nowPaid ? Timestamp.fromDate(now) : invoice.paidAt,
      });
      remaining -= take;
    }
  }

  DateTime _monthStart(DateTime d) => DateTime(d.year, d.month, 1);

  String _periodKey(DateTime m) =>
      '${m.year.toString().padLeft(4, '0')}-${m.month.toString().padLeft(2, '0')}';
}

final rentInvoiceRepositoryProvider = Provider<RentInvoiceRepository>((ref) {
  return RentInvoiceRepository();
});