import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyModel {
  final String propertyId;
  final String ownerId;
  final String? managerId;
  final String? caretakerId;
  final String name;
  final String description;
  final String location;
  final String county;
  final String status;
  final String? coverImageUrl;
  final String propertyType;
  final List<String> amenities;
  final DateTime createdAt;
  final int totalUnits;
  final int availableUnits;

  PropertyModel({
    required this.propertyId,
    required this.ownerId,
    this.managerId,
    this.caretakerId,
    required this.name,
    required this.description,
    required this.location,
    required this.county,
    this.status = 'active',
    this.coverImageUrl,
    this.propertyType = '',
    List<String>? amenities,
    DateTime? createdAt,
    this.totalUnits = 0,
    this.availableUnits = 0,
  })  : amenities = amenities ?? const [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'propertyId': propertyId,
        'ownerId': ownerId,
        'managerId': managerId,
        'caretakerId': caretakerId,
        'name': name,
        'description': description,
        'location': location,
        'county': county,
        'status': status,
        'coverImageUrl': coverImageUrl,
        'propertyType': propertyType,
        'amenities': amenities,
        'createdAt': Timestamp.fromDate(createdAt),
        'totalUnits': totalUnits,
        'availableUnits': availableUnits,
      };

  factory PropertyModel.fromMap(Map<String, dynamic> map, String id) {
    return PropertyModel(
      propertyId: id,
      ownerId: map['ownerId'] ?? '',
      managerId: map['managerId'],
      caretakerId: map['caretakerId'],
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      county: map['county'] ?? '',
      status: map['status'] ?? 'active',
      coverImageUrl: map['coverImageUrl'],
      propertyType: map['propertyType'] ?? '',
      amenities: List<String>.from(map['amenities'] ?? const []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalUnits: map['totalUnits'] ?? 0,
      availableUnits: map['availableUnits'] ?? 0,
    );
  }

  PropertyModel copyWith({int? totalUnits, int? availableUnits, String? status, String? propertyType, List<String>? amenities, String? ownerId, String? managerId, String? caretakerId}) {
    return PropertyModel(
      propertyId: propertyId,
      ownerId: ownerId ?? this.ownerId,
      managerId: managerId ?? this.managerId,
      caretakerId: caretakerId ?? this.caretakerId,
      name: name,
      description: description,
      location: location,
      county: county,
      status: status ?? this.status,
      coverImageUrl: coverImageUrl,
      propertyType: propertyType ?? this.propertyType,
      amenities: amenities ?? this.amenities,
      createdAt: createdAt,
      totalUnits: totalUnits ?? this.totalUnits,
      availableUnits: availableUnits ?? this.availableUnits,
    );
  }
}
