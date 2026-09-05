import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/payment_model.dart';
import '../screens/receipt_screen.dart';

class PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  final VoidCallback? onTap;

  const PaymentCard({super.key, required this.payment, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap ?? () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptScreen(payment: payment))),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _methodColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _methodIcon,
                  color: _methodColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Helpers.formatCurrency(payment.amount),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          payment.method.toUpperCase(),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          Helpers.formatDate(payment.paidAt),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (payment.reference.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.receipt_outlined, size: 20),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptScreen(payment: payment))),
                  tooltip: 'View Receipt',
                ),
              _statusChip(payment.status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'completed':
        color = AppColors.success;
        break;
      case 'pending':
        color = AppColors.warning;
        break;
      case 'failed':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Color get _methodColor {
    switch (payment.method) {
      case 'mpesa':
        return const Color(0xFF4CAF50);
      case 'cash':
        return const Color(0xFFFFA726);
      case 'bank_transfer':
        return AppColors.primary;
      case 'cheque':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData get _methodIcon {
    switch (payment.method) {
      case 'mpesa':
        return Icons.phone_android;
      case 'cash':
        return Icons.money;
      case 'bank_transfer':
        return Icons.account_balance;
      case 'cheque':
        return Icons.receipt_long;
      default:
        return Icons.payment;
    }
  }
}
