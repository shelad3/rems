import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/models/notification_model.dart';

final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return const Stream.empty();
  return ref.read(notificationRepositoryProvider).getNotifications(userId);
});

final unreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.valueOrNull?.where((n) => !n.read).length ?? 0;
});
