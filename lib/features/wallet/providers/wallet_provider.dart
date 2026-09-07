import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/mpesa_request_model.dart';
import '../../../data/models/wallet_model.dart';
import '../../../data/models/wallet_transaction_model.dart';
import '../../../data/repositories/mpesa_request_repository.dart';
import '../../../data/repositories/wallet_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/mpesa_service.dart';

class WalletNotifier extends ChangeNotifier {
  final WalletRepository _repository;
  final MpesaRequestRepository _mpesaRequestRepository;
  final MpesaService _mpesaService = MpesaService();
  bool _loading = false;
  String? _error;

  WalletNotifier(this._repository, this._mpesaRequestRepository);

  bool get loading => _loading;
  String? get error => _error;

  Future<void> ensureWallet(String uid) async {
    _loading = true;
    notifyListeners();
    try {
      await _repository.ensureWallet(uid);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, String>> topUp({
    required String uid,
    required double amount,
    required String phone,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final checkoutId = await _mpesaService.stkPush(
        amount: amount,
        phone: phone,
        accountReference: 'WALLETTOPUP',
        transactionDesc: 'Wallet Top-up',
      );
      await _mpesaRequestRepository.createRequest(
        MpesaRequestModel(
          checkoutRequestId: checkoutId,
          tenantUid: uid,
          propertyId: 'wallet',
          amount: amount,
          intent: 'wallet_deposit',
        ),
      );

      final completer = Completer<Map<String, String>>();
      StreamSubscription<MpesaRequestModel?>? sub;
      final timer = Timer(const Duration(seconds: 90), () {
        sub?.cancel();
        if (!completer.isCompleted) {
          completer.complete({
            'status': 'timeout',
            'message': 'No confirmation received. Check your M-Pesa statement.',
          });
        }
      });
      sub = _mpesaRequestRepository.streamRequest(checkoutId).listen((request) {
        if (request == null) return;
        if (request.status == 'completed') {
          timer.cancel();
          sub?.cancel();
          completer.complete({
            'status': 'completed',
            'message': 'Top-up successful! Receipt: ${request.receipt}',
          });
        } else if (request.status == 'failed' || request.status == 'mismatch') {
          timer.cancel();
          sub?.cancel();
          completer.complete({
            'status': request.status,
            'message': request.status == 'mismatch'
                ? 'Amount mismatch detected. Contact support.'
                : 'Payment failed. Please try again.',
          });
        }
      }, onError: (e) {
        timer.cancel();
        if (!completer.isCompleted) {
          completer.complete({'status': 'error', 'message': '$e'});
        }
      });
      return await completer.future;
    } catch (e) {
      _error = e.toString();
      return {'status': 'error', 'message': e.toString()};
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> withdraw({
    required String uid,
    required double amount,
    String? phone,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.requestWithdrawal(uid: uid, amount: amount, phone: phone);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> processWithdrawal(String txnId) {
    return _repository.processWithdrawal(txnId);
  }
}

final walletProvider = ChangeNotifierProvider<WalletNotifier>((ref) {
  return WalletNotifier(
    ref.read(walletRepositoryProvider),
    ref.read(mpesaRequestRepositoryProvider),
  );
});

final currentWalletProvider = StreamProvider<WalletModel>((ref) {
  final uid = ref.watch(currentUserProvider).value?.uid ?? '';
  if (uid.isEmpty) return Stream.empty();
  ref.read(walletRepositoryProvider).ensureWallet(uid);
  return ref
      .read(walletRepositoryProvider)
      .walletStream(uid)
      .where((w) => w != null)
      .map((w) => w!);
});

final walletTransactionsProvider = StreamProvider<List<WalletTransactionModel>>((ref) {
  final uid = ref.watch(currentUserProvider).value?.uid ?? '';
  if (uid.isEmpty) return Stream.empty();
  return ref.read(walletRepositoryProvider).transactionsStream(uid);
});

final pendingWithdrawalsProvider =
    StreamProvider<List<WalletTransactionModel>>((ref) {
  return ref.read(walletRepositoryProvider).pendingWithdrawalsStream();
});