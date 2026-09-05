import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyModel {
  final String propertyId;
  final String ownerId;
  final String? managerId;
  final String name;
  final String description;
  final String location;
  final String county;
  final String status;
  final String? coverImageUrl;
  final DateTime createdAt;
  final int totalUnits;
  final int availableUnits;

  PropertyModel({
    required this.propertyId,
    required this.ownerId,
    this.managerId,
    required this.name,
    required this.description,
    required this.location,
    required this.county,
    this.status = 'active',
    this.coverImageUrl,
    DateTime? createdAt,
    this.totalUnits = 0,
    this.availableUnits = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'propertyId': propertyId,
        'ownerId': ownerId,
        'managerId': managerId,
        'name': name,
        'description': description,
        'location': location,
        'county': county,
        'status': status,
        'coverImageUrl': coverImageUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'totalUnits': totalUnits,
        'availableUnits': availableUnits,
      };

  factory PropertyModel.fromMap(Map<String, dynamic> map, String id) {
    return PropertyModel(
      propertyId: id,
      ownerId: map['ownerId'] ?? '',
      managerId: map['managerId'],
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      county: map['county'] ?? '',
      status: map['status'] ?? 'active',
      coverImageUrl: map['coverImageUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalUnits: map['totalUnits'] ?? 0,
      availableUnits: map['availableUnits'] ?? 0,
    );
  }

  PropertyModel copyWith({int? totalUnits, int? availableUnits, String? status}) {
    return PropertyModel(
      propertyId: propertyId,
      ownerId: ownerId,
      managerId: managerId,
      name: name,
      description: description,
      location: location,
      county: county,
      status: status ?? this.status,
      coverImageUrl: coverImageUrl,
      createdAt: createdAt,
      totalUnits: totalUnits ?? this.totalUnits,
      availableUnits: availableUnits ?? this.availableUnits,
    );
  }
}
