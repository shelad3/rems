import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/payment_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../providers/lease_provider.dart';
import '../../providers/auth_provider.dart';
import 'add_payment_screen.dart';
import 'pay_rent_screen.dart';

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().loadPayments();
      context.read<LeaseProvider>().loadLeases();
    });
  }

  IconData _methodIcon(String method) {
    switch (method) {
      case 'M-Pesa':
        return Icons.phone_android;
      case 'Card':
        return Icons.credit_card;
      case 'Bank Transfer':
        return Icons.account_balance;
      case 'Cash':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');
    final dateFormat = DateFormat('MMM dd, yyyy');
    final user = authProvider.user;
    final isTenant = user?.role == 'tenant';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          if (!isTenant)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddPaymentScreen()),
              ),
            ),
        ],
      ),
      body: paymentProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Cards
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.green.withValues(alpha: 0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text('Collected',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.green)),
                                Text(
                                  currencyFormat
                                      .format(paymentProvider.totalCollected),
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          color: Colors.orange.withValues(alpha: 0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text('Due Monthly',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.orange)),
                                Text(
                                  currencyFormat
                                      .format(paymentProvider.totalDue),
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Pay Rent button (for tenants)
                if (isTenant)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () {
                          final tenantProvider =
                              context.read<TenantProvider>();
                          final leaseProvider = context.read<LeaseProvider>();
                          final tenant = tenantProvider.tenants
                              .where((t) => t.id == user?.tenantId)
                              .firstOrNull;
                          final activeLease = leaseProvider.leases
                              .where((l) =>
                                  l.tenantId == user?.tenantId && l.isActive)
                              .firstOrNull;
                          if (tenant != null && activeLease != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PayRentScreen(
                                  leaseId: activeLease.id!,
                                  tenantId: tenant.id!,
                                  rentAmount: activeLease.rentAmount,
                                  tenantName: tenant.name,
                                  unitNumber: 'Unit ${activeLease.unitId}',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.payments),
                        label: const Text('Pay Rent Now'),
                      ),
                    ),
                  ),

                // Payment List
                Expanded(
                  child: paymentProvider.payments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payment_outlined,
                                  size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('No payments yet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium),
                              const SizedBox(height: 8),
                              if (!isTenant)
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const AddPaymentScreen()),
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Record Payment'),
                                ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => paymentProvider.loadPayments(),
                          child: ListView.builder(
                            itemCount: paymentProvider.payments.length,
                            itemBuilder: (context, index) {
                              final payment =
                                  paymentProvider.payments[index];
                              final tenant = context
                                  .read<TenantProvider>()
                                  .getTenantById(payment.tenantId);
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _statusColor(
                                            payment.status)
                                        .withValues(alpha: 0.1),
                                    child: Icon(
                                      _methodIcon(payment.paymentMethod),
                                      color:
                                          _statusColor(payment.status),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    currencyFormat.format(payment.amount),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${tenant?.name ?? 'Unknown'} • ${payment.paymentType}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      if (payment.mpesaReceipt != null)
                                        Text(
                                          'Receipt: ${payment.mpesaReceipt}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600]),
                                        ),
                                      if (payment.transactionId != null)
                                        Text(
                                          'Ref: ${payment.transactionId?.substring(0, 16)}...',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500]),
                                        ),
                                      if (payment.lateFee > 0)
                                        Text(
                                          'Late fee: ${currencyFormat.format(payment.lateFee)}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.orange),
                                        ),
                                      if (payment.periodStart != null)
                                        Text(
                                          '${dateFormat.format(payment.periodStart!)} - ${payment.periodEnd != null ? dateFormat.format(payment.periodEnd!) : ''}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500]),
                                        ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        dateFormat
                                            .format(payment.paymentDate),
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600]),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _statusColor(payment.status)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          payment.status,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                _statusColor(payment.status),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        payment.paymentMethod,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
