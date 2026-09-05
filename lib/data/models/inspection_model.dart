import 'package:cloud_firestore/cloud_firestore.dart';

class InspectionModel {
  final String inspectionId;
  final String propertyId;
  final String unitId;
  final String inspectorId;
  final String condition;
  final String notes;
  final List<String> checkItems;
  final DateTime createdAt;

  InspectionModel({
    required this.inspectionId,
    required this.propertyId,
    required this.unitId,
    required this.inspectorId,
    this.condition = 'good',
    this.notes = '',
    this.checkItems = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'inspectionId': inspectionId,
        'propertyId': propertyId,
        'unitId': unitId,
        'inspectorId': inspectorId,
        'condition': condition,
        'notes': notes,
        'checkItems': checkItems,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory InspectionModel.fromMap(Map<String, dynamic> map, String id) {
    return InspectionModel(
      inspectionId: id,
      propertyId: map['propertyId'] ?? '',
      unitId: map['unitId'] ?? '',
      inspectorId: map['inspectorId'] ?? '',
      condition: map['condition'] ?? 'good',
      notes: map['notes'] ?? '',
      checkItems: List<String>.from(map['checkItems'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
