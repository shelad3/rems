class CommunicationLog {
  final int? id;
  final int? propertyId;
  final int? unitId;
  final int? tenantId;
  final int? ownerId;
  final String type;
  final String subject;
  final String notes;
  final String direction;
  final DateTime communicationDate;
  final DateTime createdAt;

  CommunicationLog({
    this.id,
    this.propertyId,
    this.unitId,
    this.tenantId,
    this.ownerId,
    this.type = 'Phone',
    this.subject = '',
    this.notes = '',
    this.direction = 'Outbound',
    DateTime? communicationDate,
    DateTime? createdAt,
  })  : communicationDate = communicationDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'property_id': propertyId,
      'unit_id': unitId,
      'tenant_id': tenantId,
      'owner_id': ownerId,
      'type': type,
      'subject': subject,
      'notes': notes,
      'direction': direction,
      'communication_date': communicationDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CommunicationLog.fromMap(Map<String, dynamic> map) {
    return CommunicationLog(
      id: map['id'] as int?,
      propertyId: map['property_id'] as int?,
      unitId: map['unit_id'] as int?,
      tenantId: map['tenant_id'] as int?,
      ownerId: map['owner_id'] as int?,
      type: (map['type'] as String?) ?? 'Phone',
      subject: (map['subject'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      direction: (map['direction'] as String?) ?? 'Outbound',
      communicationDate: DateTime.parse(map['communication_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory CommunicationLog.fromFirestore(Map<String, dynamic> map, String docId) {
    return CommunicationLog(
      id: int.tryParse(docId),
      propertyId: int.tryParse(map['propertyId']?.toString() ?? ''),
      unitId: int.tryParse(map['unitId']?.toString() ?? ''),
      tenantId: int.tryParse(map['tenantId']?.toString() ?? ''),
      ownerId: int.tryParse(map['ownerId']?.toString() ?? ''),
      type: map['type'] as String? ?? 'Phone',
      subject: map['subject'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      direction: map['direction'] as String? ?? 'Outbound',
      communicationDate: DateTime.tryParse(map['communicationDate'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'propertyId': propertyId,
      'unitId': unitId,
      'tenantId': tenantId,
      'ownerId': ownerId,
      'type': type,
      'subject': subject,
      'notes': notes,
      'direction': direction,
      'communicationDate': communicationDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }



  CommunicationLog copyWith({
    int? id,
    int? propertyId,
    int? unitId,
    int? tenantId,
    int? ownerId,
    String? type,
    String? subject,
    String? notes,
    String? direction,
    DateTime? communicationDate,
    DateTime? createdAt,
  }) {
    return CommunicationLog(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      tenantId: tenantId ?? this.tenantId,
      ownerId: ownerId ?? this.ownerId,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      notes: notes ?? this.notes,
      direction: direction ?? this.direction,
      communicationDate: communicationDate ?? this.communicationDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
