import 'package:cloud_firestore/cloud_firestore.dart';

class UnitModel {
  final String unitId;
  final String propertyId;
  final String? buildingId;
  final String unitNumber;
  final String unitType;
  final int bedrooms;
  final double rentAmount;
  final double depositAmount;
  final bool occupied;
  final String? tenantId;
  final String? caretakerId;
  final String status;
  final List<String> photos;
  final DateTime createdAt;

  UnitModel({
    required this.unitId,
    required this.propertyId,
    this.buildingId,
    required this.unitNumber,
    this.unitType = 'bedsitter',
    this.bedrooms = 0,
    required this.rentAmount,
    required this.depositAmount,
    this.occupied = false,
    this.tenantId,
    this.caretakerId,
    this.status = 'vacant',
    List<String>? photos,
    DateTime? createdAt,
  })  : photos = photos ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'unitId': unitId,
        'propertyId': propertyId,
        'buildingId': buildingId,
        'unitNumber': unitNumber,
        'unitType': unitType,
        'bedrooms': bedrooms,
        'rentAmount': rentAmount,
        'depositAmount': depositAmount,
        'occupied': occupied,
        'tenantId': tenantId,
        'caretakerId': caretakerId,
        'status': status,
        'photos': photos,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory UnitModel.fromMap(Map<String, dynamic> map, String id) {
    return UnitModel(
      unitId: id,
      propertyId: map['propertyId'] ?? '',
      buildingId: map['buildingId'],
      unitNumber: map['unitNumber'] ?? '',
      unitType: map['unitType'] ?? 'bedsitter',
      bedrooms: map['bedrooms'] ?? 0,
      rentAmount: (map['rentAmount'] ?? 0).toDouble(),
      depositAmount: (map['depositAmount'] ?? 0).toDouble(),
      occupied: map['occupied'] ?? false,
      tenantId: map['tenantId'],
      caretakerId: map['caretakerId'],
      status: map['status'] ?? 'vacant',
      photos: List<String>.from(map['photos'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  UnitModel copyWith({
    bool? occupied,
    String? tenantId,
    String? status,
  }) {
    return UnitModel(
      unitId: unitId,
      propertyId: propertyId,
      buildingId: buildingId,
      unitNumber: unitNumber,
      unitType: unitType,
      bedrooms: bedrooms,
      rentAmount: rentAmount,
      depositAmount: depositAmount,
      occupied: occupied ?? this.occupied,
      tenantId: tenantId ?? this.tenantId,
      caretakerId: caretakerId,
      status: status ?? this.status,
      photos: photos,
      createdAt: createdAt,
    );
  }
}
