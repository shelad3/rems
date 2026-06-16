class Inspection {
  final int? id;
  final int propertyId;
  final int? unitId;
  final String title;
  final String type;
  final String overallCondition;
  final String notes;
  final DateTime inspectionDate;
  final DateTime createdAt;

  Inspection({
    this.id,
    required this.propertyId,
    this.unitId,
    required this.title,
    this.type = 'Move-in',
    this.overallCondition = 'Good',
    this.notes = '',
    DateTime? inspectionDate,
    DateTime? createdAt,
  })  : inspectionDate = inspectionDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'property_id': propertyId,
      'unit_id': unitId,
      'title': title,
      'type': type,
      'overall_condition': overallCondition,
      'notes': notes,
      'inspection_date': inspectionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Inspection.fromMap(Map<String, dynamic> map) {
    return Inspection(
      id: map['id'] as int?,
      propertyId: map['property_id'] as int,
      unitId: map['unit_id'] as int?,
      title: map['title'] as String,
      type: (map['type'] as String?) ?? 'Move-in',
      overallCondition: (map['overall_condition'] as String?) ?? 'Good',
      notes: (map['notes'] as String?) ?? '',
      inspectionDate: DateTime.parse(map['inspection_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory Inspection.fromFirestore(Map<String, dynamic> map, String docId) {
    return Inspection(
      id: int.tryParse(docId),
      propertyId: int.tryParse(map['propertyId'].toString()) ?? 0,
      unitId: int.tryParse(map['unitId']?.toString() ?? ''),
      title: map['title'] as String? ?? '',
      type: map['type'] as String? ?? 'Move-in',
      overallCondition: map['overallCondition'] as String? ?? 'Good',
      notes: map['notes'] as String? ?? '',
      inspectionDate: DateTime.tryParse(map['inspectionDate'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'propertyId': propertyId,
      'unitId': unitId,
      'title': title,
      'type': type,
      'overallCondition': overallCondition,
      'notes': notes,
      'inspectionDate': inspectionDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Inspection copyWith({
    int? id,
    int? propertyId,
    int? unitId,
    String? title,
    String? type,
    String? overallCondition,
    String? notes,
    DateTime? inspectionDate,
    DateTime? createdAt,
  }) {
    return Inspection(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      title: title ?? this.title,
      type: type ?? this.type,
      overallCondition: overallCondition ?? this.overallCondition,
      notes: notes ?? this.notes,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class InspectionItem {
  final int? id;
  final int inspectionId;
  final String roomName;
  final String category;
  final String condition;
  final String notes;
  final String? photoPath;

  InspectionItem({
    this.id,
    required this.inspectionId,
    required this.roomName,
    this.category = 'General',
    this.condition = 'Good',
    this.notes = '',
    this.photoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'inspection_id': inspectionId,
      'room_name': roomName,
      'category': category,
      'condition': condition,
      'notes': notes,
      'photo_path': photoPath,
    };
  }

  factory InspectionItem.fromMap(Map<String, dynamic> map) {
    return InspectionItem(
      id: map['id'] as int?,
      inspectionId: map['inspection_id'] as int,
      roomName: map['room_name'] as String,
      category: (map['category'] as String?) ?? 'General',
      condition: (map['condition'] as String?) ?? 'Good',
      notes: (map['notes'] as String?) ?? '',
      photoPath: map['photo_path'] as String?,
    );
  }

  factory InspectionItem.fromFirestore(Map<String, dynamic> map, String docId) {
    return InspectionItem(
      id: int.tryParse(docId),
      inspectionId: int.tryParse(map['inspectionId'].toString()) ?? 0,
      roomName: map['roomName'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      condition: map['condition'] as String? ?? 'Good',
      notes: map['notes'] as String? ?? '',
      photoPath: map['photoPath'] as String?,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'inspectionId': inspectionId,
      'roomName': roomName,
      'category': category,
      'condition': condition,
      'notes': notes,
      'photoPath': photoPath,
    };
  }



  InspectionItem copyWith({
    int? id,
    int? inspectionId,
    String? roomName,
    String? category,
    String? condition,
    String? notes,
    String? photoPath,
  }) {
    return InspectionItem(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      roomName: roomName ?? this.roomName,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}
