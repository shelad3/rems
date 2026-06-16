class UserProfile {
  final int? localId;
  final String uid;
  final String email;
  final String name;
  final String role;
  final String phone;
  final bool isActive;
  final int? ownerId;
  final int? tenantId;
  final DateTime createdAt;

  UserProfile({
    this.localId,
    required this.uid,
    required this.email,
    this.name = '',
    this.role = 'tenant',
    this.phone = '',
    this.isActive = true,
    this.ownerId,
    this.tenantId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isOwner => role == 'owner';
  bool get isLandlord => role == 'landlord';
  bool get isCaretaker => role == 'caretaker';
  bool get isTenant => role == 'tenant';

  bool get canManageProperties =>
      role == 'landlord';
  bool get canManageApplications =>
      role == 'caretaker' || role == 'landlord';
  bool get canManageMaintenance =>
      role == 'caretaker' || role == 'landlord';
  bool get isReadOnly => role == 'owner';

  Map<String, dynamic> toMap() {
    return {
      if (localId != null) 'id': localId,
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'is_active': isActive ? 1 : 0,
      'owner_id': ownerId,
      'tenant_id': tenantId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'role': role,
      'isActive': isActive,
      'email': email,
      'ownerId': ownerId,
      'tenantId': tenantId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      localId: map['id'] as int?,
      uid: map['uid'] as String,
      email: map['email'] as String,
      name: (map['name'] as String?) ?? '',
      role: (map['role'] as String?) ?? 'tenant',
      phone: (map['phone'] as String?) ?? '',
      isActive: map['is_active'] == true || map['is_active'] == 1 || map['isActive'] == true || map['isActive'] == 1,
      ownerId: map['owner_id'] as int?,
      tenantId: map['tenant_id'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  factory UserProfile.fromFirestore(Map<String, dynamic> map, String docId) {
    return UserProfile(
      uid: docId,
      email: (map['email'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      role: (map['role'] as String?) ?? 'tenant',
      phone: (map['phone'] as String?) ?? '',
      isActive: (map['isActive'] as bool?) ?? true,
      ownerId: (map['ownerId'] as int?) ?? (map['owner_id'] as int?),
      tenantId: (map['tenantId'] as int?) ?? (map['tenant_id'] as int?),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  UserProfile copyWith({
    int? localId,
    String? uid,
    String? email,
    String? name,
    String? role,
    String? phone,
    bool? isActive,
    int? ownerId,
    int? tenantId,
    DateTime? createdAt,
  }) {
    return UserProfile(
      localId: localId ?? this.localId,
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      ownerId: ownerId ?? this.ownerId,
      tenantId: tenantId ?? this.tenantId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
