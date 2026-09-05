import 'package:cloud_firestore/cloud_firestore.dart';

class WalletTransactionModel {
  final String id;
  final String userId;
  final String type;
  final String source;
  final double amount;
  final double balanceAfter;
  final String status;
  final String? referenceId;
  final String description;
  final DateTime createdAt;

  WalletTransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.source,
    required this.amount,
    required this.balanceAfter,
    this.status = 'completed',
    this.referenceId,
    this.description = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isCredit => type == 'credit';

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'type': type,
        'source': source,
        'amount': amount,
        'balanceAfter': balanceAfter,
        'status': status,
        'referenceId': referenceId,
        'description': description,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory WalletTransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return WalletTransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'credit',
      source: map['source'] ?? 'adjustment',
      amount: (map['amount'] ?? 0).toDouble(),
      balanceAfter: (map['balanceAfter'] ?? 0).toDouble(),
      status: map['status'] ?? 'completed',
      referenceId: map['referenceId'],
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}