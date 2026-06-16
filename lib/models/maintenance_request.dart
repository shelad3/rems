class MaintenanceRequest {
  final int? id;
  final int unitId;
  final int tenantId;
  final String title;
  final String description;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  MaintenanceRequest({
    this.id,
    required this.unitId,
    required this.tenantId,
    required this.title,
    required this.description,
    this.priority = 'Medium',
    this.status = 'Pending',
    DateTime? createdAt,
    this.resolvedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'unit_id': unitId,
      'tenant_id': tenantId,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  factory MaintenanceRequest.fromMap(Map<String, dynamic> map) {
    return MaintenanceRequest(
      id: map['id'] as int?,
      unitId: map['unit_id'] as int,
      tenantId: map['tenant_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      priority: (map['priority'] as String?) ?? 'Medium',
      status: (map['status'] as String?) ?? 'Pending',
      createdAt: DateTime.parse(map['created_at'] as String),
      resolvedAt: map['resolved_at'] != null
          ? DateTime.parse(map['resolved_at'] as String)
          : null,
    );
  }

  factory MaintenanceRequest.fromFirestore(Map<String, dynamic> map, String docId) {
    return MaintenanceRequest(
      id: int.tryParse(docId),
      unitId: int.tryParse(map['unitId'].toString()) ?? 0,
      tenantId: int.tryParse(map['tenantId'].toString()) ?? 0,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      priority: map['priority'] as String? ?? 'Medium',
      status: map['status'] as String? ?? 'Pending',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      resolvedAt: map['resolvedAt'] != null ? DateTime.tryParse(map['resolvedAt'] as String) : null,
    );
  }



  Map<String, dynamic> toFirestoreMap() {
    return {
      'unitId': unitId,
      'tenantId': tenantId,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  MaintenanceRequest copyWith({
    int? id,
    int? unitId,
    int? tenantId,
    String? title,
    String? description,
    String? priority,
    String? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return MaintenanceRequest(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      tenantId: tenantId ?? this.tenantId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
