import 'package:cloud_firestore/cloud_firestore.dart';

class StaffModel {
  final String staffId;
  final String propertyId;
  final String userId;
  final String role;
  final List<String> permissions;
  final String status;
  final List<String> assignedBuildings;
  final DateTime createdAt;

  StaffModel({
    required this.staffId,
    required this.propertyId,
    required this.userId,
    required this.role,
    List<String>? permissions,
    this.status = 'active',
    List<String>? assignedBuildings,
    DateTime? createdAt,
  })  : permissions = permissions ?? [],
        assignedBuildings = assignedBuildings ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'staffId': staffId,
        'propertyId': propertyId,
        'userId': userId,
        'role': role,
        'permissions': permissions,
        'status': status,
        'assignedBuildings': assignedBuildings,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory StaffModel.fromMap(Map<String, dynamic> map, String id) {
    return StaffModel(
      staffId: id,
      propertyId: map['propertyId'] ?? '',
      userId: map['userId'] ?? '',
      role: map['role'] ?? '',
      permissions: List<String>.from(map['permissions'] ?? []),
      status: map['status'] ?? 'active',
      assignedBuildings: List<String>.from(map['assignedBuildings'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
