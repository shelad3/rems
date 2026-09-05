import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/helpers.dart';
import '../data/models/maintenance_ticket_model.dart';

class MaintenanceCard extends StatelessWidget {
  final MaintenanceTicketModel ticket;
  final VoidCallback? onTap;

  const MaintenanceCard({super.key, required this.ticket, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _priorityColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.build_outlined, color: _priorityColor),
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
                            ticket.description,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _statusChip(ticket.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ticket.category} · ${ticket.priority} priority',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Helpers.timeAgo(ticket.createdAt),
                      style: const TextStyle(fontSize: 12, color: AppColors.textHint),
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

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'open':
        color = AppColors.warning;
        break;
      case 'in_progress':
        color = AppColors.info;
        break;
      case 'resolved':
        color = AppColors.success;
        break;
      default:
        color = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Color get _priorityColor {
    switch (ticket.priority) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }
}
