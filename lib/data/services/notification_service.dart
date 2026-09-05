import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/routes/app_routes.dart';
import '../../core/routes/navigation.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      String? token = await _messaging.getToken();
      if (token != null) {
        await saveFcmToken(token);
      }

      _messaging.onTokenRefresh.listen(saveFcmToken);
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<void> saveFcmToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({'fcmToken': token});
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore.collection('notifications').add({
      'recipientId': user.uid,
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'type': message.data['type'] ?? 'general',
      'relatedId': message.data['relatedId'],
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _handleNotificationTap(RemoteMessage message) async {
    final type = message.data['type'];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = Navigation.navigatorKey.currentState;
      if (navigator == null) return;

      final String route;
      switch (type) {
        case 'message':
          route = AppRoutes.messageDetail;
          break;
        case 'payment':
          route = AppRoutes.paymentDetail;
          break;
        case 'maintenance':
          route = AppRoutes.maintenanceDetail;
          break;
        case 'lease':
          route = AppRoutes.tenantLease;
          break;
        case 'announcement':
          route = AppRoutes.notificationCenter;
          break;
        default:
          route = AppRoutes.notificationCenter;
      }

      navigator.pushNamed(route);
    });
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
