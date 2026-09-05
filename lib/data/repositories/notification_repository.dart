import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/firebase_service.dart';

class NotificationRepository {
  final FirebaseService _firebase = FirebaseService();

  Future<void> createNotification(NotificationModel notification) async {
    await _firebase.notificationsCollection.doc(notification.notificationId).set(notification.toMap());
  }

  Stream<List<NotificationModel>> getNotifications(String recipientId) {
    return _firebase.notificationsCollection
        .where('recipientId', isEqualTo: recipientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<int> getUnreadCount(String recipientId) async {
    final snapshot = await _firebase.notificationsCollection
        .where('recipientId', isEqualTo: recipientId)
        .where('read', isEqualTo: false)
        .get();
    return snapshot.docs.length;
  }

  Future<void> markAsRead(String notificationId) async {
    await _firebase.notificationsCollection.doc(notificationId).update({'read': true});
  }

  Future<void> markAllAsRead(String recipientId) async {
    final snapshot = await _firebase.notificationsCollection
        .where('recipientId', isEqualTo: recipientId)
        .where('read', isEqualTo: false)
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.update({'read': true});
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});
