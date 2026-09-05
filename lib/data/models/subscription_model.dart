import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String subscriptionId;
  final String ownerId;
  final String planId;
  final String status;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool autoRenew;
  final DateTime createdAt;

  SubscriptionModel({
    required this.subscriptionId,
    required this.ownerId,
    required this.planId,
    this.status = 'active',
    required this.startsAt,
    required this.endsAt,
    this.autoRenew = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'subscriptionId': subscriptionId,
        'ownerId': ownerId,
        'planId': planId,
        'status': status,
        'startsAt': Timestamp.fromDate(startsAt),
        'endsAt': Timestamp.fromDate(endsAt),
        'autoRenew': autoRenew,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory SubscriptionModel.fromMap(Map<String, dynamic> map, String id) {
    return SubscriptionModel(
      subscriptionId: id,
      ownerId: map['ownerId'] ?? '',
      planId: map['planId'] ?? '',
      status: map['status'] ?? 'active',
      startsAt: (map['startsAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endsAt: (map['endsAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      autoRenew: map['autoRenew'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
