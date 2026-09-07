import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/wallet_model.dart';
import '../models/wallet_transaction_model.dart';
import '../services/firebase_service.dart';
import '../services/mpesa_service.dart';

class WalletRepository {
  final FirebaseService _firebase = FirebaseService();

  DocumentReference _walletRef(String uid) => _firebase.walletsCollection.doc(uid);
  CollectionReference get _txnRef => _firebase.walletTransactionsCollection;

  Future<void> ensureWallet(String uid) async {
    final ref = _walletRef(uid);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set(
        WalletModel(userId: uid).toMap()
          ..['createdAt'] = FieldValue.serverTimestamp(),
        SetOptions(merge: true),
      );
    }
  }

  Stream<WalletModel?> walletStream(String uid) {
    return _walletRef(uid).snapshots().map(
          (snap) => snap.exists
              ? WalletModel.fromMap(snap.data() as Map<String, dynamic>, uid)
              : null,
        );
  }

  Future<String?> primaryAdminUid() async {
    try {
      final snap = await _firebase.usersCollection
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();
      return snap.docs.isEmpty ? null : snap.docs.first.id;
    } catch (_) {
      return null;
    }
  }

  Future<WalletModel?> getWallet(String uid) async {
    final doc = await _walletRef(uid).get();
    if (!doc.exists) return null;
    return WalletModel.fromMap(doc.data() as Map<String, dynamic>, uid);
  }

  Stream<List<WalletTransactionModel>> transactionsStream(String uid) {
    return _txnRef
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WalletTransactionModel.fromMap(
                d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Stream<List<WalletTransactionModel>> pendingWithdrawalsStream() {
    return _txnRef
        .where('type', isEqualTo: 'debit')
        .where('source', isEqualTo: 'withdrawal')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WalletTransactionModel.fromMap(
                d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Future<double?> credit({
    required String uid,
    required double amount,
    required String source,
    String? referenceId,
    String description = '',
  }) async {
    await ensureWallet(uid);
    double balanceAfter = 0;
    try {
      await _firebase.firestore.runTransaction((txn) async {
        final ref = _walletRef(uid);
        final snap = await txn.get(ref);
        if (!snap.exists) {
          throw Exception('Wallet not found');
        }
        final w = WalletModel.fromMap(snap.data() as Map<String, dynamic>, uid);
        balanceAfter = w.balance + amount;
        txn.update(ref, {
          'balance': balanceAfter,
          'totalCredited': w.totalCredited + amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      await _recordTxn(
        uid: uid,
        type: 'credit',
        source: source,
        amount: amount,
        balanceAfter: balanceAfter,
        referenceId: referenceId,
        description: description,
      );
      return balanceAfter;
    } catch (_) {
      return null;
    }
  }

  Future<double?> debit({
    required String uid,
    required double amount,
    required String source,
    String? referenceId,
    String description = '',
  }) async {
    await ensureWallet(uid);
    double balanceAfter = 0;
    try {
      await _firebase.firestore.runTransaction((txn) async {
        final ref = _walletRef(uid);
        final snap = await txn.get(ref);
        if (!snap.exists) {
          throw Exception('Wallet not found');
        }
        final w = WalletModel.fromMap(snap.data() as Map<String, dynamic>, uid);
        if (w.balance < amount) {
          throw Exception('Insufficient balance');
        }
        balanceAfter = w.balance - amount;
        txn.update(ref, {
          'balance': balanceAfter,
          'totalDebited': w.totalDebited + amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      await _recordTxn(
        uid: uid,
        type: 'debit',
        source: source,
        amount: amount,
        balanceAfter: balanceAfter,
        referenceId: referenceId,
        description: description,
      );
      return balanceAfter;
    } catch (_) {
      return null;
    }
  }

  Future<void> requestWithdrawal({
    required String uid,
    required double amount,
    String? phone,
    String description = 'Wallet withdrawal request',
  }) async {
    final wallet = await getWallet(uid);
    if (wallet == null || wallet.balance < amount) {
      throw Exception('Insufficient balance');
    }
    final doc = _txnRef.doc();
    final txn = WalletTransactionModel(
      id: doc.id,
      userId: uid,
      type: 'debit',
      source: 'withdrawal',
      amount: amount,
      balanceAfter: wallet.balance,
      status: 'pending',
      description: '$description ${phone == null ? '' : '(to $phone)'}'.trim(),
    ).toMap()
      ..['createdAt'] = FieldValue.serverTimestamp();
    if (phone != null && phone.trim().isNotEmpty) {
      txn['phone'] = phone.trim();
      txn['mpesaPhone'] = phone.trim();
    }
    await doc.set(txn);
  }

  Future<String?> processWithdrawal(String txnId) async {
    try {
      final response = await http.post(
        Uri.parse(MpesaService().callbackUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'b2c', 'txnId': txnId}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['ok'] == true) return null;
      return (body['reason'] ?? 'Withdrawal payout failed') as String;
    } catch (e) {
      return 'Could not reach payment server: $e';
    }
  }

  Future<void> _recordTxn({
    required String uid,
    required String type,
    required String source,
    required double amount,
    required double balanceAfter,
    String? referenceId,
    String description = '',
  }) async {
    final doc = _txnRef.doc();
    await doc.set(
      WalletTransactionModel(
        id: doc.id,
        userId: uid,
        type: type,
        source: source,
        amount: amount,
        balanceAfter: balanceAfter,
        referenceId: referenceId,
        description: description,
      ).toMap()
        ..['createdAt'] = FieldValue.serverTimestamp(),
    );
  }
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository();
});