import 'package:cloud_firestore/cloud_firestore.dart';

String makeConversationId(String uid1, String uid2) {
  final ids = [uid1, uid2]..sort();
  return '${ids[0]}_${ids[1]}';
}

class MessageModel {
  final String messageId;
  final String propertyId;
  final String senderId;
  final String receiverId;
  final String text;
  final String? attachmentUrl;
  final bool read;
  final DateTime createdAt;
  final String? senderName;
  final String? senderPhotoUrl;
  final String conversationId;

  MessageModel({
    required this.messageId,
    required this.propertyId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.attachmentUrl,
    this.read = false,
    DateTime? createdAt,
    this.senderName,
    this.senderPhotoUrl,
  })  : createdAt = createdAt ?? DateTime.now(),
        conversationId = makeConversationId(senderId, receiverId);

  Map<String, dynamic> toMap() => {
        'messageId': messageId,
        'propertyId': propertyId,
        'senderId': senderId,
        'receiverId': receiverId,
        'conversationId': conversationId,
        'text': text,
        'attachmentUrl': attachmentUrl,
        'read': read,
        'createdAt': Timestamp.fromDate(createdAt),
        'senderName': senderName,
        'senderPhotoUrl': senderPhotoUrl,
      };

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      messageId: id,
      propertyId: map['propertyId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      attachmentUrl: map['attachmentUrl'],
      read: map['read'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      senderName: map['senderName'],
      senderPhotoUrl: map['senderPhotoUrl'],
    );
  }

  MessageModel copyWith({bool? read}) {
    return MessageModel(
      messageId: messageId,
      propertyId: propertyId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      attachmentUrl: attachmentUrl,
      read: read ?? this.read,
      createdAt: createdAt,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
    );
  }
}
