import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/payment_model.dart';
import '../widgets/admin_logout_button.dart';

final _adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final users = await ref.read(userRepositoryProvider).getAllUsers();
  final properties = await ref.read(propertyRepositoryProvider).getAllProperties();
  final payments = await ref.read(paymentRepositoryProvider).getAllPayments();

  final totalUsers = users.length;
  final totalProperties = properties.length;
  final activeTenants = users.where((u) => u.role == 'tenant' && u.status == 'active').length;
  final totalIncome = payments
      .where((p) => p.status == 'paid')
      .fold<double>(0.0, (sum, p) => sum + p.amount);

  return AdminStats(
    totalUsers: totalUsers,
    totalProperties: totalProperties,
    totalIncome: totalIncome,
    activeTenants: activeTenants,
    usersByRole: _countByRole(users),
    monthlyRevenue: _monthlyRevenue(payments),
  );
});

List<MapEntry<String, double>> _monthlyRevenue(List<PaymentModel> payments) {
  final now = DateTime.now();
  final result = <String, double>{};
  for (int i = 5; i >= 0; i--) {
    final month = DateTime(now.year, now.month - i, 1);
    result['${month.year}-${month.month.toString().padLeft(2, '0')}'] = 0;
  }
  for (final p in payments) {
    if (p.status != 'paid') continue;
    final key = '${p.paidAt.year}-${p.paidAt.month.toString().padLeft(2, '0')}';
    if (result.containsKey(key)) {
      result[key] = result[key]! + p.amount;
    }
  }
  return result.entries.toList();
}

Map<String, int> _countByRole(List<UserModel> users) {
  final counts = <String, int>{};
  for (final u in users) {
    counts[u.role] = (counts[u.role] ?? 0) + 1;
  }
  return counts;
}

class AdminStats {
  final int totalUsers;
  final int totalProperties;
  final double totalIncome;
  final int activeTenants;
  final Map<String, int> usersByRole;
  final List<MapEntry<String, double>> monthlyRevenue;

  AdminStats({
    required this.totalUsers,
    required this.totalProperties,
    required this.totalIncome,
    required this.activeTenants,
    required this.usersByRole,
    required this.monthlyRevenue,
  });
}

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_adminStatsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: const [AdminLogoutButton()],
      ),
      body: statsAsync.when(
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _StatCard(
                    icon: Icons.people_outline,
                    label: 'Total Users',
                    value: '${stats.totalUsers}',
                    color: AppColors.primary,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(
                    icon: Icons.home_work_outlined,
                    label: 'Properties',
                    value: '${stats.totalProperties}',
                    color: AppColors.success,
                  )),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _StatCard(
                    icon: Icons.payment_outlined,
                    label: 'Revenue',
                    value: Helpers.formatCurrency(stats.totalIncome),
                    color: AppColors.warning,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(
                    icon: Icons.people,
                    label: 'Active Tenants',
                    value: '${stats.activeTenants}',
                    color: AppColors.info,
                  )),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Users by Role', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: stats.usersByRole.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(e.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w500)),
                          ),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: stats.totalUsers > 0 ? e.value / stats.totalUsers : 0,
                              backgroundColor: AppColors.surface,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Platform Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Container(
                  height: 220,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Revenue (last 6 months)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final entry in stats.monthlyRevenue)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (entry.value > 0)
                                        Text(
                                          entry.value >= 1000
                                              ? '${(entry.value / 1000).toStringAsFixed(0)}k'
                                              : entry.value.toStringAsFixed(0),
                                          style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                                        ),
                                      const SizedBox(height: 4),
                                      Container(
                                        height: entry.value == 0
                                            ? 2
                                            : (entry.value / (stats.monthlyRevenue.map((e) => e.value).reduce((a, b) => a > b ? a : b)) * 150).clamp(4, 150),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        entry.key.split('-')[1],
                                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
