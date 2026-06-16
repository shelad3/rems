class Approval {
  final int? id;
  final String referenceType;
  final int referenceId;
  final String title;
  final String description;
  final double? amount;
  final String requestedBy;
  final String? requestedByName;
  final String status;
  final String? reviewedBy;
  final String? reviewNotes;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  Approval({
    this.id,
    required this.referenceType,
    required this.referenceId,
    required this.title,
    this.description = '',
    this.amount,
    this.requestedBy = '',
    this.requestedByName,
    this.status = 'Pending',
    this.reviewedBy,
    this.reviewNotes,
    this.reviewedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'title': title,
      'description': description,
      'amount': amount,
      'requested_by': requestedBy,
      'requested_by_name': requestedByName,
      'status': status,
      'reviewed_by': reviewedBy,
      'review_notes': reviewNotes,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Approval.fromMap(Map<String, dynamic> map) {
    return Approval(
      id: map['id'] as int?,
      referenceType: map['reference_type'] as String,
      referenceId: map['reference_id'] as int,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      amount: (map['amount'] as num?)?.toDouble(),
      requestedBy: (map['requested_by'] as String?) ?? '',
      requestedByName: map['requested_by_name'] as String?,
      status: (map['status'] as String?) ?? 'Pending',
      reviewedBy: map['reviewed_by'] as String?,
      reviewNotes: map['review_notes'] as String?,
      reviewedAt: map['reviewed_at'] != null
          ? DateTime.tryParse(map['reviewed_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory Approval.fromFirestore(Map<String, dynamic> map, String docId) {
    return Approval(
      id: int.tryParse(docId),
      referenceType: map['referenceType'] as String? ?? '',
      referenceId: int.tryParse(map['referenceId'].toString()) ?? 0,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      amount: double.tryParse(map['amount']?.toString() ?? ''),
      requestedBy: map['requestedBy'] as String? ?? '',
      requestedByName: map['requestedByName'] as String?,
      status: map['status'] as String? ?? 'Pending',
      reviewedBy: map['reviewedBy'] as String?,
      reviewNotes: map['reviewNotes'] as String?,
      reviewedAt: map['reviewedAt'] != null ? DateTime.tryParse(map['reviewedAt'] as String) : null,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'referenceType': referenceType,
      'referenceId': referenceId,
      'title': title,
      'description': description,
      'amount': amount,
      'requestedBy': requestedBy,
      'requestedByName': requestedByName,
      'status': status,
      'reviewedBy': reviewedBy,
      'reviewNotes': reviewNotes,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }



  Approval copyWith({
    int? id,
    String? referenceType,
    int? referenceId,
    String? title,
    String? description,
    double? amount,
    String? requestedBy,
    String? requestedByName,
    String? status,
    String? reviewedBy,
    String? reviewNotes,
    DateTime? reviewedAt,
    DateTime? createdAt,
  }) {
    return Approval(
      id: id ?? this.id,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      requestedBy: requestedBy ?? this.requestedBy,
      requestedByName: requestedByName ?? this.requestedByName,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
