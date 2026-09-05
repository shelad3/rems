import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/repositories/payment_repository.dart';
import 'owner_comparison_screen.dart';
import '../providers/owner_analytics_provider.dart';
import '../widgets/property_selector.dart';
import '../widgets/revenue_chart.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/screens/notification_center_screen.dart';
import '../../../widgets/premium_gate.dart';

class OwnerOverviewScreen extends ConsumerWidget {
  const OwnerOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
        actions: [
          Consumer(builder: (context, ref, _) {
            final unreadCount = ref.watch(unreadCountProvider);
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('$unreadCount', style: const TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
      body: userAsync.when(
        data: (user) => _buildContent(context, ref, user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, UserModel? user) {
    final metricsAsync = ref.watch(ownerAggregatedMetricsProvider);
    final selectedId = ref.watch(selectedPropertyProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PropertySelector(),
          const SizedBox(height: 16),
          metricsAsync.when(
            data: (metrics) => _KpiRow(metrics: metrics),
            loading: () => const Row(
              children: [
                Expanded(child: Card(child: SizedBox(height: 100))),
                SizedBox(width: 12),
                Expanded(child: Card(child: SizedBox(height: 100))),
                SizedBox(width: 12),
                Expanded(child: Card(child: SizedBox(height: 100))),
              ],
            ),
            error: (_, __) => const _KpiRow(metrics: null),
          ),
          const SizedBox(height: 24),
          PremiumGate(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Revenue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  child: Container(
                    height: 220,
                    padding: const EdgeInsets.all(16),
                    child: _RevenueChartContent(selectedPropertyId: selectedId),
                  ),
                ),
              ],
            ),
            lockedOverlay: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Revenue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  child: Container(
                    height: 220,
                    padding: const EdgeInsets.all(16),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline, size: 32, color: AppColors.textHint),
                          SizedBox(height: 8),
                          Text('Revenue charts available on Premium',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _ActionCard(
                icon: Icons.add_business_outlined,
                label: 'Add Property',
                onTap: () => Navigator.pushNamed(context, AppRoutes.addProperty),
              )),
              const SizedBox(width: 12),
              Expanded(child: _ActionCard(
                icon: Icons.compare_arrows,
                label: 'Compare',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OwnerComparisonScreen()),
                ),
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _ActionCard(
                icon: Icons.description_outlined,
                label: 'Reports',
                onTap: () => Navigator.pushNamed(context, AppRoutes.ownerReports),
              )),
              const SizedBox(width: 12),
              Expanded(child: _ActionCard(
                icon: Icons.workspace_premium_outlined,
                label: 'Upgrade',
                onTap: () => Navigator.pushNamed(context, '/upgrade'),
              )),
            ],
          ),
          if (user?.subscriptionTier == 'free') ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Upgrade to Premium',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 4),
                        const Text('Unlock unlimited properties, analytics & more',
                            style: TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/upgrade'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                    child: const Text('Upgrade'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RevenueChartContent extends ConsumerWidget {
  final String? selectedPropertyId;
  const _RevenueChartContent({this.selectedPropertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyId = selectedPropertyId;
    if (propertyId == null) {
      return const Center(child: Text('Select a property', style: TextStyle(color: AppColors.textSecondary)));
    }

    return StreamBuilder<List<PaymentModel>>(
      stream: ref.read(paymentRepositoryProvider).getPaymentsByProperty(propertyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final payments = snapshot.data!;
        final monthlyData = _aggregateMonthly(payments);
        return RevenueChart(data: monthlyData);
      },
    );
  }

  List<MonthlyRevenue> _aggregateMonthly(List<PaymentModel> payments) {
    final Map<String, double> monthly = {};
    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      monthly[key] = 0;
    }

    for (final payment in payments) {
      final key = '${payment.paidAt.year}-${payment.paidAt.month.toString().padLeft(2, '0')}';
      if (monthly.containsKey(key)) {
        monthly[key] = (monthly[key] ?? 0) + payment.amount;
      }
    }

    return monthly.entries.map((e) {
      final parts = e.key.split('-');
      final month = DateFormat('MMM').format(DateTime(int.parse(parts[0]), int.parse(parts[1])));
      return MonthlyRevenue(month: month, amount: e.value);
    }).toList();
  }
}

class _KpiRow extends StatelessWidget {
  final OwnerMetrics? metrics;
  const _KpiRow({this.metrics});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _KpiCard(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Income',
          value: metrics != null ? Helpers.formatCurrency(metrics!.totalIncome) : 'KES 0',
          color: AppColors.success,
        )),
        const SizedBox(width: 12),
        Expanded(child: _KpiCard(
          icon: Icons.people_outline,
          label: 'Occupancy',
          value: metrics != null ? '${metrics!.occupancyRate.toStringAsFixed(0)}%' : '0%',
          color: AppColors.primary,
        )),
        const SizedBox(width: 12),
        Expanded(child: _KpiCard(
          icon: Icons.warning_amber_outlined,
          label: 'Arrears',
          value: metrics != null ? Helpers.formatCurrency(metrics!.arrears) : 'KES 0',
          color: AppColors.error,
        )),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _KpiCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 32, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
