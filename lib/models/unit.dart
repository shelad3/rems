class Unit {
  final int? id;
  final int propertyId;
  final String unitNumber;
  final int bedrooms;
  final int bathrooms;
  final double squareFeet;
  final double rentAmount;
  final double securityDeposit;
  final bool isOccupied;
  final String notes;
  final DateTime createdAt;

  Unit({
    this.id,
    required this.propertyId,
    required this.unitNumber,
    this.bedrooms = 1,
    this.bathrooms = 1,
    this.squareFeet = 0,
    this.rentAmount = 0,
    this.securityDeposit = 0,
    this.isOccupied = false,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'property_id': propertyId,
      'unit_number': unitNumber,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'square_feet': squareFeet,
      'rent_amount': rentAmount,
      'security_deposit': securityDeposit,
      'is_occupied': isOccupied ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'] as int?,
      propertyId: map['property_id'] as int,
      unitNumber: map['unit_number'] as String,
      bedrooms: (map['bedrooms'] as int?) ?? 1,
      bathrooms: (map['bathrooms'] as int?) ?? 1,
      squareFeet: (map['square_feet'] as num?)?.toDouble() ?? 0,
      rentAmount: (map['rent_amount'] as num?)?.toDouble() ?? 0,
      securityDeposit: (map['security_deposit'] as num?)?.toDouble() ?? 0,
      isOccupied: (map['is_occupied'] as int?) == 1,
      notes: (map['notes'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory Unit.fromFirestore(Map<String, dynamic> map, String docId) {
    return Unit(
      id: int.tryParse(docId),
      propertyId: int.tryParse(map['propertyId'].toString()) ?? 0,
      unitNumber: map['unitNumber'] as String? ?? '',
      bedrooms: int.tryParse(map['bedrooms'].toString()) ?? 1,
      bathrooms: int.tryParse(map['bathrooms'].toString()) ?? 1,
      squareFeet: double.tryParse(map['squareFeet'].toString()) ?? 0,
      rentAmount: double.tryParse(map['rentAmount'].toString()) ?? 0,
      securityDeposit: double.tryParse(map['securityDeposit'].toString()) ?? 0,
      isOccupied: map['isOccupied'] as bool? ?? false,
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'propertyId': propertyId,
      'unitNumber': unitNumber,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'squareFeet': squareFeet,
      'rentAmount': rentAmount,
      'securityDeposit': securityDeposit,
      'isOccupied': isOccupied,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Unit copyWith({
    int? id,
    int? propertyId,
    String? unitNumber,
    int? bedrooms,
    int? bathrooms,
    double? squareFeet,
    double? rentAmount,
    double? securityDeposit,
    bool? isOccupied,
    String? notes,
    DateTime? createdAt,
  }) {
    return Unit(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      unitNumber: unitNumber ?? this.unitNumber,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      squareFeet: squareFeet ?? this.squareFeet,
      rentAmount: rentAmount ?? this.rentAmount,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      isOccupied: isOccupied ?? this.isOccupied,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
