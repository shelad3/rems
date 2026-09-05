import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/notification_model.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const NotificationTile({super.key, required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _typeColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_typeIcon, color: _typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.read ? FontWeight.normal : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!notification.read)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Helpers.timeAgo(notification.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _typeIcon {
    switch (notification.type) {
      case 'request_approved':
        return Icons.check_circle;
      case 'request_rejected':
        return Icons.cancel;
      case 'maintenance':
      case 'maintenance_created':
      case 'maintenance_updated':
        return Icons.build;
      case 'payment':
      case 'payment_received':
      case 'payment_due':
        return Icons.payment;
      case 'message':
      case 'new_message':
        return Icons.chat;
      case 'announcement':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  Color get _typeColor {
    switch (notification.type) {
      case 'request_approved':
        return AppColors.success;
      case 'request_rejected':
        return AppColors.error;
      case 'maintenance':
      case 'maintenance_created':
      case 'maintenance_updated':
        return AppColors.warning;
      case 'payment':
      case 'payment_received':
        return AppColors.success;
      case 'payment_due':
        return AppColors.error;
      case 'message':
      case 'new_message':
        return AppColors.info;
      case 'announcement':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }
}
