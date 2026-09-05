import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String notificationId;
  final String recipientId;
  final String title;
  final String body;
  final String type;
  final String? relatedId;
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.recipientId,
    required this.title,
    required this.body,
    this.type = 'general',
    this.relatedId,
    this.read = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'notificationId': notificationId,
        'recipientId': recipientId,
        'title': title,
        'body': body,
        'type': type,
        'relatedId': relatedId,
        'read': read,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      notificationId: id,
      recipientId: map['recipientId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'general',
      relatedId: map['relatedId'],
      read: map['read'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  NotificationModel copyWith({bool? read}) {
    return NotificationModel(
      notificationId: notificationId,
      recipientId: recipientId,
      title: title,
      body: body,
      type: type,
      relatedId: relatedId,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }
}
