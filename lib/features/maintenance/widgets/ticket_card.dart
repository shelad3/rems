import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/maintenance_ticket_model.dart';

class TicketCard extends StatelessWidget {
  final MaintenanceTicketModel ticket;
  final VoidCallback? onTap;

  const TicketCard({super.key, required this.ticket, this.onTap});

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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _categoryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_categoryIcon, color: _categoryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _priorityColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ticket.priority.toUpperCase(),
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _priorityColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ticket.category,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        _statusChip(ticket.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ticket.description,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
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
      case 'acknowledged':
        color = AppColors.info;
        break;
      case 'in_progress':
        color = AppColors.primary;
        break;
      case 'resolved':
        color = AppColors.success;
        break;
      default:
        color = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Color get _priorityColor {
    switch (ticket.priority) {
      case 'emergency':
        return AppColors.error;
      case 'high':
        return Colors.deepOrange;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  Color get _categoryColor {
    switch (ticket.category) {
      case 'plumbing':
        return AppColors.info;
      case 'electrical':
        return AppColors.warning;
      case 'structural':
        return Colors.brown;
      case 'appliance':
        return AppColors.primary;
      case 'pest':
        return Colors.teal;
      case 'cleaning':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData get _categoryIcon {
    switch (ticket.category) {
      case 'plumbing':
        return Icons.water_drop;
      case 'electrical':
        return Icons.electrical_services;
      case 'structural':
        return Icons.construction;
      case 'appliance':
        return Icons.kitchen;
      case 'pest':
        return Icons.bug_report;
      case 'cleaning':
        return Icons.cleaning_services;
      default:
        return Icons.build_outlined;
    }
  }
}
