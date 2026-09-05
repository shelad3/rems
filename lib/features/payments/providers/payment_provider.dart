import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/rent_invoice_repository.dart';
import '../../../data/models/payment_model.dart';

class PaymentNotifier extends ChangeNotifier {
  final PaymentRepository _repository;
  final RentInvoiceRepository _invoiceRepository;
  bool _loading = false;
  String? _error;

  PaymentNotifier(this._repository, this._invoiceRepository);

  bool get loading => _loading;
  String? get error => _error;

  Future<void> recordPayment({
    required String tenantId,
    required String propertyId,
    required String unitId,
    required double amount,
    required String method,
    String? reference,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final paymentId = FirebaseFirestore.instance.collection('payments').doc().id;
      final payment = PaymentModel(
        paymentId: paymentId,
        tenantId: tenantId,
        propertyId: propertyId,
        unitId: unitId,
        amount: amount,
        method: method,
        reference: reference ?? '',
        status: 'completed',
      );
      await _repository.recordPayment(payment);
      await _invoiceRepository.applyPaymentToInvoices(
        unitId: unitId,
        amount: amount,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

final paymentProvider = ChangeNotifierProvider<PaymentNotifier>((ref) {
  return PaymentNotifier(
    ref.read(paymentRepositoryProvider),
    ref.read(rentInvoiceRepositoryProvider),
  );
});
