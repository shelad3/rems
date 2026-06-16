class Task {
  final int? id;
  final int? propertyId;
  final int? unitId;
  final int? tenantId;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String? assignedTo;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final DateTime createdAt;

  Task({
    this.id,
    this.propertyId,
    this.unitId,
    this.tenantId,
    required this.title,
    this.description = '',
    this.priority = 'Medium',
    this.status = 'Pending',
    this.assignedTo,
    this.dueDate,
    this.completedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'property_id': propertyId,
      'unit_id': unitId,
      'tenant_id': tenantId,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'assigned_to': assignedTo,
      'due_date': dueDate?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      propertyId: map['property_id'] as int?,
      unitId: map['unit_id'] as int?,
      tenantId: map['tenant_id'] as int?,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      priority: (map['priority'] as String?) ?? 'Medium',
      status: (map['status'] as String?) ?? 'Pending',
      assignedTo: map['assigned_to'] as String?,
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'] as String)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory Task.fromFirestore(Map<String, dynamic> map, String docId) {
    return Task(
      id: int.tryParse(docId),
      propertyId: int.tryParse(map['propertyId']?.toString() ?? ''),
      unitId: int.tryParse(map['unitId']?.toString() ?? ''),
      tenantId: int.tryParse(map['tenantId']?.toString() ?? ''),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      priority: map['priority'] as String? ?? 'Medium',
      status: map['status'] as String? ?? 'Pending',
      assignedTo: map['assignedTo'] as String?,
      dueDate: map['dueDate'] != null ? DateTime.tryParse(map['dueDate'] as String) : null,
      completedAt: map['completedAt'] != null ? DateTime.tryParse(map['completedAt'] as String) : null,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'propertyId': propertyId,
      'unitId': unitId,
      'tenantId': tenantId,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'assignedTo': assignedTo,
      'dueDate': dueDate?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }



  Task copyWith({
    int? id,
    int? propertyId,
    int? unitId,
    int? tenantId,
    String? title,
    String? description,
    String? priority,
    String? status,
    String? assignedTo,
    DateTime? dueDate,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      tenantId: tenantId ?? this.tenantId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
