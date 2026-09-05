import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String phone;
  final String email;
  final String role;
  final String status;
  final String? photoUrl;
  final String? county;
  final String? idNumber;
  final String? companyName;
  final String? businessRegistration;
  final String? taxInfo;
  final String? employmentStatus;
  final String? occupation;
  final String? emergencyContact;
  final String? nextOfKin;
  final String? assignedPropertyCode;
  final String? invitationCode;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final String? currentPropertyId;
  final String? currentUnitId;
  final String subscriptionTier;
  final bool isVerified;
  final String? preferredLanguage;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.role,
    required this.status,
    this.photoUrl,
    this.county,
    this.idNumber,
    this.companyName,
    this.businessRegistration,
    this.taxInfo,
    this.employmentStatus,
    this.occupation,
    this.emergencyContact,
    this.nextOfKin,
    this.assignedPropertyCode,
    this.invitationCode,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    this.currentPropertyId,
    this.currentUnitId,
    this.subscriptionTier = 'free',
    this.isVerified = false,
    this.preferredLanguage,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastLoginAt = lastLoginAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'role': role,
        'status': status,
        'photoUrl': photoUrl,
        'county': county,
        'idNumber': idNumber,
        'companyName': companyName,
        'businessRegistration': businessRegistration,
        'taxInfo': taxInfo,
        'employmentStatus': employmentStatus,
        'occupation': occupation,
        'emergencyContact': emergencyContact,
        'nextOfKin': nextOfKin,
        'assignedPropertyCode': assignedPropertyCode,
        'invitationCode': invitationCode,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastLoginAt': Timestamp.fromDate(lastLoginAt),
        'currentPropertyId': currentPropertyId,
        'currentUnitId': currentUnitId,
        'subscriptionTier': subscriptionTier,
        'isVerified': isVerified,
        'preferredLanguage': preferredLanguage,
      };

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'tenant',
      status: map['status'] ?? 'pending',
      photoUrl: map['photoUrl'],
      county: map['county'],
      idNumber: map['idNumber'],
      companyName: map['companyName'],
      businessRegistration: map['businessRegistration'],
      taxInfo: map['taxInfo'],
      employmentStatus: map['employmentStatus'],
      occupation: map['occupation'],
      emergencyContact: map['emergencyContact'],
      nextOfKin: map['nextOfKin'],
      assignedPropertyCode: map['assignedPropertyCode'],
      invitationCode: map['invitationCode'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (map['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      currentPropertyId: map['currentPropertyId'],
      currentUnitId: map['currentUnitId'],
      subscriptionTier: map['subscriptionTier'] ?? 'free',
      isVerified: map['isVerified'] ?? false,
      preferredLanguage: map['preferredLanguage'],
    );
  }

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? email,
    String? role,
    String? status,
    String? photoUrl,
    String? county,
    String? currentPropertyId,
    String? currentUnitId,
    String? subscriptionTier,
    bool? isVerified,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
      county: county ?? this.county,
      idNumber: idNumber,
      companyName: companyName,
      businessRegistration: businessRegistration,
      taxInfo: taxInfo,
      employmentStatus: employmentStatus,
      occupation: occupation,
      emergencyContact: emergencyContact,
      nextOfKin: nextOfKin,
      assignedPropertyCode: assignedPropertyCode,
      invitationCode: invitationCode,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      currentPropertyId: currentPropertyId ?? this.currentPropertyId,
      currentUnitId: currentUnitId ?? this.currentUnitId,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      isVerified: isVerified ?? this.isVerified,
      preferredLanguage: preferredLanguage,
    );
  }
}
