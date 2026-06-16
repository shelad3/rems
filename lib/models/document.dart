class Document {
  final int? id;
  final int? propertyId;
  final int? unitId;
  final int? tenantId;
  final String name;
  final String filePath;
  final String category;
  final String notes;
  final DateTime createdAt;

  Document({
    this.id,
    this.propertyId,
    this.unitId,
    this.tenantId,
    required this.name,
    required this.filePath,
    this.category = 'Other',
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'property_id': propertyId,
      'unit_id': unitId,
      'tenant_id': tenantId,
      'name': name,
      'file_path': filePath,
      'category': category,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'] as int?,
      propertyId: map['property_id'] as int?,
      unitId: map['unit_id'] as int?,
      tenantId: map['tenant_id'] as int?,
      name: map['name'] as String,
      filePath: map['file_path'] as String,
      category: (map['category'] as String?) ?? 'Other',
      notes: (map['notes'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory Document.fromFirestore(Map<String, dynamic> map, String docId) {
    return Document(
      id: int.tryParse(docId),
      propertyId: int.tryParse(map['propertyId']?.toString() ?? ''),
      unitId: int.tryParse(map['unitId']?.toString() ?? ''),
      tenantId: int.tryParse(map['tenantId']?.toString() ?? ''),
      name: map['name'] as String? ?? '',
      filePath: map['filePath'] as String? ?? '',
      category: map['category'] as String? ?? 'Other',
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'propertyId': propertyId,
      'unitId': unitId,
      'tenantId': tenantId,
      'name': name,
      'filePath': filePath,
      'category': category,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }



  Document copyWith({
    int? id,
    int? propertyId,
    int? unitId,
    int? tenantId,
    String? name,
    String? filePath,
    String? category,
    String? notes,
    DateTime? createdAt,
  }) {
    return Document(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
