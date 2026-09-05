import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_tile.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_state.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () => _markAllRead(ref),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.notifications_none,
              title: 'No notifications',
              subtitle: 'You\'re all caught up',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: notifications.length,
            itemBuilder: (_, i) => NotificationTile(
              notification: notifications[i],
              onTap: () => _handleTap(context, ref, notifications[i]),
            ),
          );
        },
        loading: () => const ShimmerLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _markAllRead(WidgetRef ref) {
    final userId = ref.read(notificationRepositoryProvider);
    final auth = ref.read(authServiceProvider);
    final user = auth.currentUser;
    if (user != null) {
      userId.markAllAsRead(user.uid);
    }
  }

  void _handleTap(BuildContext context, WidgetRef ref, NotificationModel notification) {
    ref.read(notificationRepositoryProvider).markAsRead(notification.notificationId);
  }
}
