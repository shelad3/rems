import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceTicketModel {
  final String ticketId;
  final String tenantId;
  final String propertyId;
  final String unitId;
  final String priority;
  final String category;
  final String description;
  final List<String> photoUrls;
  final String status;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? tenantName;
  final String? tenantPhone;

  MaintenanceTicketModel({
    required this.ticketId,
    required this.tenantId,
    required this.propertyId,
    required this.unitId,
    this.priority = 'medium',
    this.category = 'general',
    required this.description,
    List<String>? photoUrls,
    this.status = 'open',
    this.assignedTo,
    DateTime? createdAt,
    this.resolvedAt,
    this.tenantName,
    this.tenantPhone,
  })  : photoUrls = photoUrls ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'ticketId': ticketId,
        'tenantId': tenantId,
        'propertyId': propertyId,
        'unitId': unitId,
        'priority': priority,
        'category': category,
        'description': description,
        'photoUrls': photoUrls,
        'status': status,
        'assignedTo': assignedTo,
        'createdAt': Timestamp.fromDate(createdAt),
        'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
        'tenantName': tenantName,
        'tenantPhone': tenantPhone,
      };

  factory MaintenanceTicketModel.fromMap(Map<String, dynamic> map, String id) {
    return MaintenanceTicketModel(
      ticketId: id,
      tenantId: map['tenantId'] ?? '',
      propertyId: map['propertyId'] ?? '',
      unitId: map['unitId'] ?? '',
      priority: map['priority'] ?? 'medium',
      category: map['category'] ?? 'general',
      description: map['description'] ?? '',
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      status: map['status'] ?? 'open',
      assignedTo: map['assignedTo'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
      tenantName: map['tenantName'],
      tenantPhone: map['tenantPhone'],
    );
  }

  MaintenanceTicketModel copyWith({String? status, String? assignedTo, DateTime? resolvedAt}) {
    return MaintenanceTicketModel(
      ticketId: ticketId,
      tenantId: tenantId,
      propertyId: propertyId,
      unitId: unitId,
      priority: priority,
      category: category,
      description: description,
      photoUrls: photoUrls,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      tenantName: tenantName,
      tenantPhone: tenantPhone,
    );
  }
}
