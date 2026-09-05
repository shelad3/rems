import 'package:cloud_firestore/cloud_firestore.dart';

class WalletModel {
  final String userId;
  final double balance;
  final double totalCredited;
  final double totalDebited;
  final DateTime updatedAt;

  WalletModel({
    required this.userId,
    this.balance = 0,
    this.totalCredited = 0,
    this.totalDebited = 0,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'balance': balance,
        'totalCredited': totalCredited,
        'totalDebited': totalDebited,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory WalletModel.fromMap(Map<String, dynamic> map, String id) {
    return WalletModel(
      userId: map['userId'] ?? id,
      balance: (map['balance'] ?? 0).toDouble(),
      totalCredited: (map['totalCredited'] ?? 0).toDouble(),
      totalDebited: (map['totalDebited'] ?? 0).toDouble(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}