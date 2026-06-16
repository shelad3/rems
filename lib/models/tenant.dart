class Tenant {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String emergencyContact;
  final String emergencyPhone;
  final String idNumber;
  final String notes;
  final DateTime createdAt;

  Tenant({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.emergencyContact = '',
    this.emergencyPhone = '',
    this.idNumber = '',
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'emergency_contact': emergencyContact,
      'emergency_phone': emergencyPhone,
      'id_number': idNumber,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Tenant.fromMap(Map<String, dynamic> map) {
    return Tenant(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      emergencyContact: (map['emergency_contact'] as String?) ?? '',
      emergencyPhone: (map['emergency_phone'] as String?) ?? '',
      idNumber: (map['id_number'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory Tenant.fromFirestore(Map<String, dynamic> map, String docId) {
    return Tenant(
      id: int.tryParse(docId),
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      emergencyContact: map['emergencyContact'] as String? ?? '',
      emergencyPhone: map['emergencyPhone'] as String? ?? '',
      idNumber: map['idNumber'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'idNumber': idNumber,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Tenant copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? emergencyContact,
    String? emergencyPhone,
    String? idNumber,
    String? notes,
    DateTime? createdAt,
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      idNumber: idNumber ?? this.idNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
