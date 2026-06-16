import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/payment_provider.dart';

import '../../providers/maintenance_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/approval_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/payment_tile.dart';
import '../../services/pdf_export_service.dart';
import '../expenses/expense_list_screen.dart';
import '../approvals/approval_list_screen.dart';
import '../tasks/task_list_screen.dart';
import '../documents/document_list_screen.dart';
import '../inspections/inspection_list_screen.dart';
import '../communications/communication_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loadingStats = true;
  List<Map<String, dynamic>> _monthlyRevenue = [];
  final _firestore = FirestoreService.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final snapshots = await Future.wait([
        _firestore.db.collection('properties').get(),
        _firestore.db.collection('units').get(),
        _firestore.db.collection('users').where('role', isEqualTo: 'tenant').get(),
        _firestore.db.collection('leases').where('isActive', isEqualTo: true).get(),
        _firestore.db.collection('maintenance').get(),
        _firestore.db.collection('payments').where('status', isEqualTo: 'completed').get(),
      ]);

      final propertiesSnap = snapshots[0] as QuerySnapshot;
      final unitsSnap = snapshots[1] as QuerySnapshot;
      final tenantsSnap = snapshots[2] as QuerySnapshot;
      final leasesSnap = snapshots[3] as QuerySnapshot;
      final maintenanceSnap = snapshots[4] as QuerySnapshot;
      final paymentsSnap = snapshots[5] as QuerySnapshot;

      final totalProperties = propertiesSnap.docs.length;
      final totalUnits = unitsSnap.docs.length;
      final occupiedUnits = unitsSnap.docs
          .where((d) =>
              (d.data() as Map<String, dynamic>)['status'] == 'occupied')
          .length;
      final totalTenants = tenantsSnap.docs.length;
      final activeLeases = leasesSnap.docs.length;
      final openMaintenance = maintenanceSnap.docs
          .where((d) =>
              (d.data() as Map<String, dynamic>)['status'] != 'completed')
          .length;

      double totalCollected = 0;
      for (final doc in paymentsSnap.docs) {
        totalCollected +=
            ((doc.data() as Map<String, dynamic>)['amount'] as num?)?.toDouble() ?? 0;
      }

      final currentYear = DateTime.now().year;
      final monthlyRevenue = <Map<String, dynamic>>[];
      for (int m = 1; m <= 12; m++) {
        double monthTotal = 0;
        for (final doc in paymentsSnap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final dateStr = data['payment_date'] as String? ?? '';
          if (dateStr.isNotEmpty) {
            try {
              final date = DateTime.parse(dateStr);
              if (date.year == currentYear && date.month == m) {
                monthTotal += (data['amount'] as num?)?.toDouble() ?? 0;
              }
            } catch (_) {}
          }
        }
        monthlyRevenue.add({'month': '$m', 'total': monthTotal});
      }

      if (mounted) {
        setState(() {
          _stats = {
            'total_properties': totalProperties,
            'total_units': totalUnits,
            'occupied_units': occupiedUnits,
            'total_tenants': totalTenants,
            'active_leases': activeLeases,
            'open_maintenance': openMaintenance,
            'total_collected': totalCollected,
          };
          _monthlyRevenue = monthlyRevenue;
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _stats = {};
          _monthlyRevenue = [];
          _loadingStats = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final maintenanceProvider = context.watch<MaintenanceProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final approvalProvider = context.watch<ApprovalProvider>();

    return RefreshIndicator(
      onRefresh: () async {
        await _loadData();
        await Future.wait([
          paymentProvider.loadPayments(),
          maintenanceProvider.loadRequests(),
          expenseProvider.loadAllExpenses(),
          taskProvider.loadTasks(),
          approvalProvider.loadApprovals(),
        ]);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.description_outlined),
                        tooltip: 'Export Rent Roll',
                        onPressed: () =>
                            PdfExportService.instance.exportRentRoll(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.build_outlined),
                        tooltip: 'Export Maintenance Report',
                        onPressed: () =>
                            PdfExportService.instance
                                .exportMaintenanceReport(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Welcome back! Here is your portfolio overview.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            const SizedBox(height: 20),
            if (_loadingStats)
              const Center(child: CircularProgressIndicator())
            else ...[
              _buildStatsGrid(),
              const SizedBox(height: 20),
              _buildQuickActions(),
              const SizedBox(height: 20),
              _buildRevenueChart(),
              const SizedBox(height: 20),
              _buildRecentPayments(paymentProvider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final totalProperties = _stats?['total_properties'] ?? 0;
    final totalUnits = _stats?['total_units'] ?? 0;
    final occupiedUnits = _stats?['occupied_units'] ?? 0;
    final totalTenants = _stats?['total_tenants'] ?? 0;
    final activeLeases = _stats?['active_leases'] ?? 0;
    final openMaintenance = _stats?['open_maintenance'] ?? 0;
    final totalCollected = _stats?['total_collected'] ?? 0;
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        StatCard(
          title: 'Properties',
          value: '$totalProperties',
          icon: Icons.business,
          color: Colors.blue,
        ),
        StatCard(
          title: 'Units',
          value: '$totalUnits',
          subtitle: '$occupiedUnits occupied',
          icon: Icons.apartment,
          color: Colors.green,
        ),
        StatCard(
          title: 'Tenants',
          value: '$totalTenants',
          icon: Icons.people,
          color: Colors.purple,
        ),
        StatCard(
          title: 'Active Leases',
          value: '$activeLeases',
          icon: Icons.description,
          color: Colors.teal,
        ),
        StatCard(
          title: 'Open Requests',
          value: '$openMaintenance',
          icon: Icons.build,
          color: openMaintenance > 0 ? Colors.orange : Colors.green,
        ),
        StatCard(
          title: 'Total Collected',
          value: currencyFormat.format(totalCollected),
          icon: Icons.account_balance,
          color: Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _actionButton(context, Icons.money_off, 'Expenses', Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseListScreen()))),
                _actionButton(context, Icons.task_alt, 'Approvals', Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApprovalListScreen()))),
                _actionButton(context, Icons.checklist, 'Tasks', Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskListScreen()))),
                _actionButton(context, Icons.description, 'Docs', Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentListScreen()))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _actionButton(context, Icons.search, 'Inspections', Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InspectionListScreen()))),
                _actionButton(context, Icons.chat_outlined, 'Comms', Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunicationListScreen()))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Revenue ${DateTime.now().year}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _monthlyRevenue.isEmpty
                  ? const Center(child: Text('No payment data yet'))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxRevenue() * 1.2,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final month = DateFormat('MMM').format(
                                DateTime(2024, group.x.toInt()),
                              );
                              return BarTooltipItem(
                                '$month\n\$${rod.toY.toStringAsFixed(0)}',
                                const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final months = [
                                  'J', 'F', 'M', 'A', 'M', 'J',
                                  'J', 'A', 'S', 'O', 'N', 'D'
                                ];
                                final index = value.toInt() - 1;
                                if (index >= 0 && index < months.length) {
                                  return Text(
                                    months[index],
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '\$${value.toInt()}',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: _getMaxRevenue() / 4,
                          drawVerticalLine: false,
                        ),
                        barGroups: _buildBarGroups(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxRevenue() {
    double max = 0;
    for (final item in _monthlyRevenue) {
      final total = (item['total'] as num?)?.toDouble() ?? 0;
      if (total > max) max = total;
    }
    return max > 0 ? max : 1000;
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(12, (index) {
      double total = 0;
      for (final item in _monthlyRevenue) {
        if (int.tryParse(item['month'] as String) == index + 1) {
          total = (item['total'] as num?)?.toDouble() ?? 0;
        }
      }
      return BarChartGroupData(
        x: index + 1,
        barRods: [
          BarChartRodData(
            toY: total,
            color: Colors.blue,
            width: 12,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  Widget _buildRecentPayments(PaymentProvider paymentProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Payments',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            paymentProvider.recentPayments.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('No payments recorded yet')),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: paymentProvider.recentPayments.length > 5
                        ? 5
                        : paymentProvider.recentPayments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = paymentProvider.recentPayments[index];
                      return PaymentTile(
                        amount: (p['amount'] as num?)?.toDouble() ?? 0,
                        tenantName: p['tenant_name'] as String? ?? 'Unknown',
                        paymentDate:
                            DateTime.parse(p['payment_date'] as String),
                        status: p['status'] as String? ?? 'Paid',
                        paymentType: p['payment_type'] as String? ?? 'Rent',
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
