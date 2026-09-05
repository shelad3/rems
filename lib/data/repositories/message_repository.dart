import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../services/firebase_service.dart';

class MessageRepository {
  final FirebaseService _firebase = FirebaseService();

  Future<void> sendMessage(MessageModel message) async {
    await _firebase.messagesCollection.doc(message.messageId).set(message.toMap());
  }

  Stream<List<MessageModel>> getConversation(String uid1, String uid2) {
    final convId = makeConversationId(uid1, uid2);
    return _firebase.messagesCollection
        .where('conversationId', isEqualTo: convId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<MessageModel>> getMessagesByProperty(String propertyId) {
    return _firebase.messagesCollection
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<int> getUnreadCount(String userId) async {
    final snapshot = await _firebase.messagesCollection
        .where('receiverId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    return snapshot.docs.length;
  }

  Future<void> markAsRead(String messageId) async {
    await _firebase.messagesCollection.doc(messageId).update({'read': true});
  }
}

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository();
});
