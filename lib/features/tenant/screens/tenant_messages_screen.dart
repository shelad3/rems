import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_widget.dart';

class TenantMessagesScreen extends ConsumerWidget {
  const TenantMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const EmptyStateWidget(title: 'Not logged in');
          return StreamBuilder<List<NotificationModel>>(
            stream: ref.read(notificationRepositoryProvider).getNotifications(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ShimmerLoading();
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final notifications = snapshot.data ?? [];
              if (notifications.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.mail_outline,
                  title: 'No messages',
                  subtitle: 'Messages and alerts will appear here',
                );
              }
              return Column(
                children: [
                  if (notifications.any((n) => !n.read))
                    TextButton(
                      onPressed: () async {
                        await ref.read(notificationRepositoryProvider).markAllAsRead(user.uid);
                      },
                      child: const Text('Mark all as read'),
                    ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final n = notifications[i];
                        return _NotificationTile(notification: n, userId: user.uid);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const ShimmerLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationModel notification;
  final String userId;

  const _NotificationTile({required this.notification, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = _iconForType(notification.type);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: notification.read ? AppColors.surface : AppColors.primary.withAlpha(25),
        child: Icon(icon, color: notification.read ? AppColors.textHint : AppColors.primary, size: 20),
      ),
      title: Text(notification.title, style: TextStyle(
        fontWeight: notification.read ? FontWeight.normal : FontWeight.w600,
      )),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(Helpers.timeAgo(notification.createdAt),
              style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
        ],
      ),
      trailing: notification.read ? null : Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
      ),
      onTap: () async {
        if (!notification.read) {
          await ref.read(notificationRepositoryProvider).markAsRead(notification.notificationId);
        }
      },
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'payment': return Icons.payment;
      case 'maintenance': return Icons.build;
      case 'lease': return Icons.description;
      case 'system': return Icons.info_outline;
      default: return Icons.notifications_outlined;
    }
  }
}
