class Vendor {
  final int? id;
  final String name;
  final String contactPerson;
  final String email;
  final String phone;
  final String category;
  final String address;
  final String notes;
  final double? hourlyRate;
  final bool isActive;
  final DateTime createdAt;

  Vendor({
    this.id,
    required this.name,
    this.contactPerson = '',
    this.email = '',
    this.phone = '',
    this.category = 'General',
    this.address = '',
    this.notes = '',
    this.hourlyRate,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'contact_person': contactPerson,
      'email': email,
      'phone': phone,
      'category': category,
      'address': address,
      'notes': notes,
      'hourly_rate': hourlyRate,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Vendor.fromMap(Map<String, dynamic> map) {
    return Vendor(
      id: map['id'] as int?,
      name: map['name'] as String,
      contactPerson: (map['contact_person'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'General',
      address: (map['address'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      hourlyRate: (map['hourly_rate'] as num?)?.toDouble(),
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Vendor copyWith({
    int? id,
    String? name,
    String? contactPerson,
    String? email,
    String? phone,
    String? category,
    String? address,
    String? notes,
    double? hourlyRate,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Vendor(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      category: category ?? this.category,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
