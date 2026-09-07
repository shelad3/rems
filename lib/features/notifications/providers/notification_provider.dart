import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/services/auth_service.dart';

final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final uid = ref.watch(currentUserProvider).value?.uid;
  if (uid == null) return const Stream.empty();
  return ref.read(notificationRepositoryProvider).getNotifications(uid);
});

final unreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.valueOrNull?.where((n) => !n.read).length ?? 0;
});
