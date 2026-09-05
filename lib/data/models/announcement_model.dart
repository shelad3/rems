import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String announcementId;
  final String propertyId;
  final String createdBy;
  final String title;
  final String body;
  final String audience;
  final DateTime createdAt;

  AnnouncementModel({
    required this.announcementId,
    required this.propertyId,
    required this.createdBy,
    required this.title,
    required this.body,
    this.audience = 'all',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'announcementId': announcementId,
        'propertyId': propertyId,
        'createdBy': createdBy,
        'title': title,
        'body': body,
        'audience': audience,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String id) {
    return AnnouncementModel(
      announcementId: id,
      propertyId: map['propertyId'] ?? '',
      createdBy: map['createdBy'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      audience: map['audience'] ?? 'all',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
