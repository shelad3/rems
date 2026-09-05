import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/helpers.dart';
import '../data/models/access_request_model.dart';

class RequestCard extends StatelessWidget {
  final AccessRequestModel request;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const RequestCard({
    super.key,
    required this.request,
    this.onTap,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withAlpha(25),
                    child: Text(
                      Helpers.getInitials(request.tenantName ?? '?'),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.tenantName ?? 'Unknown Tenant',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (request.tenantPhone != null)
                          Text(
                            request.tenantPhone!,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  _statusChip(request.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    Helpers.timeAgo(request.requestedAt),
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  if (request.desiredMoveInDate != null) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.move_to_inbox, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Move-in: ${request.desiredMoveInDate}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
              if (request.status == 'pending' && onApprove != null && onReject != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = AppColors.warning;
        break;
      case 'approved':
        color = AppColors.success;
        break;
      case 'rejected':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
