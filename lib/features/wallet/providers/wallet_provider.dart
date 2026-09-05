import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/wallet_model.dart';
import '../../../data/models/wallet_transaction_model.dart';
import '../../../data/repositories/wallet_repository.dart';
import '../../../data/services/auth_service.dart';

class WalletNotifier extends ChangeNotifier {
  final WalletRepository _repository;
  bool _loading = false;
  String? _error;

  WalletNotifier(this._repository);

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

  Future<double?> deposit({
    required String uid,
    required double amount,
    String source = 'deposit',
  }) async {
    _error = null;
    return _repository.credit(
      uid: uid,
      amount: amount,
      source: source,
      description: amount > 0 ? 'Wallet top-up' : '',
    );
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

  Future<bool> processWithdrawal(String txnId) {
    return _repository.processWithdrawal(txnId);
  }
}

final walletProvider = ChangeNotifierProvider<WalletNotifier>((ref) {
  return WalletNotifier(ref.read(walletRepositoryProvider));
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