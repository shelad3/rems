import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/lease_model.dart';

class LeaseCard extends StatelessWidget {
  final LeaseModel lease;
  final VoidCallback? onTap;
  final VoidCallback? onAcceptTerms;

  const LeaseCard({
    super.key,
    required this.lease,
    this.onTap,
    this.onAcceptTerms,
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.article_outlined, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Helpers.formatCurrency(lease.rentAmount),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Per month · ${lease.termsAccepted ? "Terms accepted" : "Terms pending"}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  _statusChip(lease.status),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  _InfoItem(label: 'Start', value: Helpers.formatDate(lease.startDate)),
                  const SizedBox(width: 24),
                  _InfoItem(label: 'End', value: Helpers.formatDate(lease.endDate)),
                  const SizedBox(width: 24),
                  _InfoItem(label: 'Deposit', value: Helpers.formatCurrency(lease.depositAmount)),
                ],
              ),
              if (!lease.termsAccepted && onAcceptTerms != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAcceptTerms,
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text('Accept Lease Terms'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
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
      case 'active':
        color = AppColors.success;
        break;
      case 'expired':
        color = AppColors.error;
        break;
      case 'pending':
        color = AppColors.warning;
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

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}
