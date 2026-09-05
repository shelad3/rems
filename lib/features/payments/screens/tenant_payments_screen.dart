import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/lease_repository.dart';
import '../../../data/repositories/rent_invoice_repository.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/models/lease_model.dart';
import '../../../data/models/rent_invoice_model.dart';
import '../widgets/payment_card.dart';
import 'mpesa_payment_screen.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_state.dart';

class TenantPaymentsScreen extends ConsumerWidget {
  const TenantPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const EmptyStateWidget(title: 'Please log in');

final paymentsAsync = ref.watch(_paymentsStreamProvider(user.uid));
            final leaseAsync = ref.watch(_leaseStreamProvider(user.uid));
            final invoicesAsync = ref.watch(_invoicesStreamProvider(user.uid));
            ref.listen(_ensureInvoiceProvider(user.uid), (previous, next) {});

            return paymentsAsync.when(
              data: (payments) {
                final leases = leaseAsync.valueOrNull ?? [];
                final invoices = invoicesAsync.valueOrNull ?? [];
                final rentAmount = leases.isNotEmpty ? leases.first.rentAmount : 0.0;
                final totalPaid = payments.fold<double>(0.0, (sum, p) => sum + p.amount);
                final currentMonthKey = _periodKey(DateTime.now());
                final unpaidInvoices = invoices.where((i) => !i.isPaid).toList();
                final currentOutstanding = unpaidInvoices
                    .where((i) => i.periodKey == currentMonthKey)
                    .fold<double>(0.0, (sum, i) => sum + i.outstanding);
                final arrears = unpaidInvoices
                    .where((i) => i.periodKey != currentMonthKey)
                    .fold<double>(0.0, (sum, i) => sum + i.outstanding);
                final fallbackOutstanding =
                    rentAmount > 0 ? rentAmount - totalPaid : 0.0;
                final outstanding = invoices.isEmpty
                    ? fallbackOutstanding.clamp(0.0, double.infinity).toDouble()
                    : currentOutstanding + arrears;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPaymentHeader(context, payments, leases, outstanding, rentAmount, totalPaid),
                    const SizedBox(height: 16),
                    if (outstanding > 0)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final propertyId = leases.isNotEmpty ? leases.first.propertyId : '';
                            final unitId = leases.isNotEmpty ? leases.first.unitId : '';
                            if (propertyId.isEmpty) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MpesaPaymentScreen(
                                  amount: outstanding,
                                  propertyId: propertyId,
                                  unitId: unitId,
                                ),
                              ),
                            ).then((paid) {
                              if (paid == true) {
                                ref.invalidate(_paymentsStreamProvider(user.uid));
                                ref.invalidate(_invoicesStreamProvider(user.uid));
                              }
                            });
                          },
                          icon: const Icon(Icons.payments),
                          label: Text('Pay KES ${outstanding.toStringAsFixed(0)}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Text('Rent Invoices',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (invoices.isEmpty)
                      const EmptyStateWidget(
                        icon: Icons.receipt_long_outlined,
                        title: 'No invoices yet',
                        subtitle: 'Your monthly rent invoice will appear here',
                      )
                    else
                      ...invoices.map((invoice) => _InvoiceTile(invoice: invoice)),
                    const SizedBox(height: 20),
                    const Text('Payment History',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (payments.isEmpty)
                      const EmptyStateWidget(
                        icon: Icons.payment_outlined,
                        title: 'No payments yet',
                        subtitle: 'Your payment history will appear here',
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: payments.length,
                        itemBuilder: (_, i) => PaymentCard(payment: payments[i]),
                      ),
                  ],
                ),
              );
            },
            loading: () => const ShimmerLoading(),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildPaymentHeader(
      BuildContext context,
      List<PaymentModel> payments,
      List<LeaseModel> leases,
      double outstanding,
      double rentAmount,
      double totalPaid) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Total Paid', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(
              Helpers.formatCurrency(totalPaid),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.success),
            ),
            const Divider(height: 28),
            Row(
              children: [
                _SummaryItem(label: 'Monthly Rent', value: Helpers.formatCurrency(rentAmount)),
                const SizedBox(width: 24),
                _SummaryItem(
                  label: 'Outstanding',
                  value: Helpers.formatCurrency(outstanding),
                  valueColor: outstanding > 0 ? AppColors.error : AppColors.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _SummaryItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: valueColor ?? AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final RentInvoiceModel invoice;
  const _InvoiceTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final paid = invoice.isPaid;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: paid
              ? AppColors.success.withValues(alpha: 0.15)
              : AppColors.error.withValues(alpha: 0.15),
          child: Icon(
            paid ? Icons.check_circle_outline : Icons.schedule,
            color: paid ? AppColors.success : AppColors.error,
          ),
        ),
        title: Text(_monthLabel(invoice.periodStart)),
        subtitle: Text(paid
            ? 'Rent settled'
            : 'Partially unpaid: ${Helpers.formatCurrency(invoice.outstanding)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Helpers.formatCurrency(invoice.amount),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              paid ? 'PAID' : 'UNPAID',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: paid ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _monthLabel(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.year}';
}

String _periodKey(DateTime m) =>
    '${m.year.toString().padLeft(4, '0')}-${m.month.toString().padLeft(2, '0')}';

final _paymentsStreamProvider = StreamProvider.family<List<PaymentModel>, String>((ref, tenantId) {
  return ref.read(paymentRepositoryProvider).getPaymentsByTenant(tenantId);
});

final _leaseStreamProvider = StreamProvider.family<List<LeaseModel>, String>((ref, tenantId) {
  return ref.read(leaseRepositoryProvider).getLeasesByTenant(tenantId);
});

final _invoicesStreamProvider = StreamProvider.family<List<RentInvoiceModel>, String>((ref, tenantId) {
  return ref.read(rentInvoiceRepositoryProvider).getInvoicesByTenant(tenantId);
});

final _ensureInvoiceProvider = FutureProvider.family<void, String>((ref, tenantId) async {
  final leases = await ref.read(leaseRepositoryProvider).getLeasesByTenant(tenantId).first;
  if (leases.isEmpty) return;
  final lease = leases.first;
  await ref.read(rentInvoiceRepositoryProvider).ensureInvoiceForMonth(
    tenantId: tenantId,
    propertyId: lease.propertyId,
    unitId: lease.unitId,
    amount: lease.rentAmount,
  );
});
