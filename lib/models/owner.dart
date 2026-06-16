class Owner {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String notes;
  final String lookingFor;
  final DateTime createdAt;

  Owner({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.notes = '',
    this.lookingFor = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'notes': notes,
      'looking_for': lookingFor,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Owner.fromMap(Map<String, dynamic> map) {
    return Owner(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String,
      notes: (map['notes'] as String?) ?? '',
      lookingFor: (map['looking_for'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory Owner.fromFirestore(Map<String, dynamic> map, String docId) {
    return Owner(
      id: int.tryParse(docId),
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      lookingFor: map['lookingFor'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'notes': notes,
      'lookingFor': lookingFor,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Owner copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? notes,
    String? lookingFor,
    DateTime? createdAt,
  }) {
    return Owner(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      lookingFor: lookingFor ?? this.lookingFor,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
