class Property {
  final int? id;
  final int ownerId;
  final String name;
  final String address;
  final String city;
  final String state;
  final String zip;
  final String type;
  final int totalUnits;
  final String notes;
  final String status;
  final DateTime createdAt;

  Property({
    this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.zip,
    this.type = 'Residential',
    this.totalUnits = 1,
    this.notes = '',
    this.status = 'rental',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isRental => status == 'rental';
  bool get isForSale => status == 'for_sale';
  bool get isUnderConstruction => status == 'under_construction';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'owner_id': ownerId,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'zip': zip,
      'type': type,
      'total_units': totalUnits,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      id: map['id'] as int?,
      ownerId: map['owner_id'] as int,
      name: map['name'] as String,
      address: map['address'] as String,
      city: map['city'] as String,
      state: map['state'] as String,
      zip: map['zip'] as String,
      type: (map['type'] as String?) ?? 'Residential',
      totalUnits: (map['total_units'] as int?) ?? 1,
      notes: (map['notes'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'rental',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory Property.fromFirestore(Map<String, dynamic> map, String docId) {
    return Property(
      id: int.tryParse(docId),
      ownerId: int.tryParse(map['ownerId'].toString()) ?? 0,
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      zip: map['zip'] as String? ?? '',
      type: map['type'] as String? ?? 'Residential',
      totalUnits: int.tryParse(map['totalUnits'].toString()) ?? 1,
      notes: map['notes'] as String? ?? '',
      status: map['status'] as String? ?? 'rental',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'address': address,
      'city': city,
      'state': state,
      'zip': zip,
      'type': type,
      'totalUnits': totalUnits,
      'notes': notes,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  Property copyWith({
    int? id,
    int? ownerId,
    String? name,
    String? address,
    String? city,
    String? state,
    String? zip,
    String? type,
    int? totalUnits,
    String? notes,
    String? status,
    DateTime? createdAt,
  }) {
    return Property(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zip: zip ?? this.zip,
      type: type ?? this.type,
      totalUnits: totalUnits ?? this.totalUnits,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
