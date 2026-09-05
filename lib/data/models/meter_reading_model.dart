import 'package:cloud_firestore/cloud_firestore.dart';

class MeterReadingModel {
  final String readingId;
  final String propertyId;
  final String unitId;
  final String type;
  final double value;
  final String readBy;
  final String notes;
  final DateTime createdAt;

  MeterReadingModel({
    required this.readingId,
    required this.propertyId,
    required this.unitId,
    required this.type,
    required this.value,
    required this.readBy,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'readingId': readingId,
        'propertyId': propertyId,
        'unitId': unitId,
        'type': type,
        'value': value,
        'readBy': readBy,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory MeterReadingModel.fromMap(Map<String, dynamic> map, String id) {
    return MeterReadingModel(
      readingId: id,
      propertyId: map['propertyId'] ?? '',
      unitId: map['unitId'] ?? '',
      type: map['type'] ?? 'water',
      value: (map['value'] as num?)?.toDouble() ?? 0,
      readBy: map['readBy'] ?? '',
      notes: map['notes'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
