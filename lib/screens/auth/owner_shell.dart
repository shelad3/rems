import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/property_provider.dart';
import '../../database/database_helper.dart';
import '../profile/profile_screen.dart';
import '../properties/property_detail_screen.dart';
import '../payments/payment_list_screen.dart';
import '../maintenance/maintenance_list_screen.dart';

class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int _currentIndex = 0;
  final FirestoreService _firestore = FirestoreService.instance;
  final DatabaseHelper _db = DatabaseHelper.instance;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(colorScheme, theme),
          _buildPropertiesList(colorScheme, theme),
          _buildRevenueTab(colorScheme, theme),
          _buildReportsTab(colorScheme, theme),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          HapticFeedback.selectionClick();
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Overview'),
          NavigationDestination(
              icon: Icon(Icons.business_outlined),
              selectedIcon: Icon(Icons.business),
              label: 'Properties'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_outlined),
              selectedIcon: Icon(Icons.account_balance),
              label: 'Revenue'),
          NavigationDestination(
              icon: Icon(Icons.assessment_outlined),
              selectedIcon: Icon(Icons.assessment),
              label: 'Reports'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }

  int _getOwnerId() {
    final auth = context.read<AuthProvider>();
    return auth.user?.ownerId ?? 0;
  }

  Widget _buildDashboard(ColorScheme colors, ThemeData theme) {
    final ownerId = _getOwnerId();

    return Scaffold(
      appBar: AppBar(title: const Text('My Portfolio')),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<PaymentProvider>().loadPayments();
          await context.read<ExpenseProvider>().loadAllExpenses();
          await context.read<PropertyProvider>().loadProperties();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatsRow(colors),
            const SizedBox(height: 16),
            _buildOccupancyCard(colors),
            const SizedBox(height: 16),
            _buildRevenueChart(colors, theme),
            const SizedBox(height: 16),
            _buildRecentPayments(colors),
            const SizedBox(height: 16),
            _buildQuickActions(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ColorScheme colors) {
    final paymentProv = context.watch<PaymentProvider>();
    final propertyProv = context.watch<PropertyProvider>();
    final ownerId = _getOwnerId();

    final myProperties = propertyProv.properties.where((p) => p.ownerId == ownerId).toList();
    final totalProps = myProperties.length;
    final collected = paymentProv.totalCollected;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _statCard(Icons.business, 'Properties', '$totalProps', colors.primary),
          const SizedBox(width: 12),
          _statCard(Icons.people, 'Tenants', '—', Colors.green),
          const SizedBox(width: 12),
          _statCard(Icons.monetization_on, 'Collected', 'KSH ${_formatKsh(collected)}', Colors.amber.shade700),
          const SizedBox(width: 12),
          _statCard(Icons.build, 'Maintenance', '—', Colors.orange),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return Card(
      child: SizedBox(
        width: 130,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOccupancyCard(ColorScheme colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.allUnitsStream(),
          builder: (context, snap) {
            final total = snap.data?.docs.length ?? 0;
            final occupied = snap.data?.docs
                    .where((d) =>
                        (d.data() as Map<String, dynamic>)['status'] == 'occupied')
                    .length ??
                0;
            final vacant = total - occupied;
            final occupancyRate = total > 0 ? occupied / total : 0.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Occupancy Overview',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statBox('Total', '$total', colors.primary),
                    _statBox('Occupied', '$occupied', Colors.green),
                    _statBox('Vacant', '$vacant', Colors.orange),
                    _statBox('Rate', '${(occupancyRate * 100).toInt()}%', Colors.blue),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: occupancyRate,
                    minHeight: 20,
                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.green),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$occupied occupied',
                        style: const TextStyle(fontSize: 11, color: Colors.green)),
                    Text('$vacant vacant',
                        style: const TextStyle(fontSize: 11, color: Colors.orange)),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRevenueChart(ColorScheme colors, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Revenue this Year',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('KSH',
                    style: TextStyle(fontSize: 12, color: colors.outline)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _db.getMonthlyRevenue(DateTime.now().year),
                builder: (context, snap) {
                  if (!snap.hasData || snap.data!.isEmpty) {
                    return Center(
                      child: Text('No revenue data yet',
                          style: TextStyle(color: colors.outline)),
                    );
                  }
                  final data = snap.data!;
                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: data.fold<double>(
                          0, (max, m) => ((m['total'] as num?)?.toDouble() ?? 0) > max
                              ? (m['total'] as num).toDouble()
                              : max) *
                          1.2,
                      barGroups: data.asMap().entries.map((e) {
                        final month = e.value['month'] as int;
                        final total = (e.value['total'] as num?)?.toDouble() ?? 0;
                        return BarChartGroupData(
                          x: month,
                          barRods: [
                            BarChartRodData(
                              toY: total,
                              color: colors.primary,
                              width: 14,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const months = ['', 'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                              return Text(months[value.toInt()],
                                  style: const TextStyle(fontSize: 10));
                            },
                            reservedSize: 22,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: data.fold<double>(0, (max, m) =>
                            ((m['total'] as num?)?.toDouble() ?? 0) > max
                                ? (m['total'] as num).toDouble() : max) / 4,
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPayments(ColorScheme colors) {
    return Consumer<PaymentProvider>(
      builder: (context, prov, _) {
        final recent = prov.recentPayments;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Payments',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => setState(() => _currentIndex = 2),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                if (recent.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text('No payments yet',
                          style: TextStyle(color: colors.outline)),
                    ),
                  )
                else
                  ...recent.take(5).map((p) {
                    final tenantName = p['tenant_name'] as String? ?? '';
                    final amount = (p['amount'] as num?)?.toDouble() ?? 0;
                    final date = p['payment_date'] as String? ?? '';
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade50,
                        child: const Icon(Icons.check_circle,
                            color: Colors.green, size: 20),
                      ),
                      title: Text(tenantName,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(date, style: const TextStyle(fontSize: 11)),
                      trailing: Text('KSH ${_formatKsh(amount)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700)),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(ColorScheme colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _actionCard(Icons.business, 'Properties', colors.primary,
                        () => setState(() => _currentIndex = 1))),
                const SizedBox(width: 8),
                Expanded(
                    child: _actionCard(Icons.account_balance, 'Revenue', Colors.green,
                        () => setState(() => _currentIndex = 2))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _actionCard(Icons.assessment, 'Reports', Colors.blue,
                        () => setState(() => _currentIndex = 3))),
                const SizedBox(width: 8),
                Expanded(
                    child: _actionCard(Icons.build, 'Maintenance', Colors.orange, () {
                  Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MaintenanceListScreen()),
                  );
                })),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertiesList(ColorScheme colors, ThemeData theme) {
    final ownerId = _getOwnerId();

    return Scaffold(
      appBar: AppBar(title: const Text('My Properties')),
      body: Consumer<PropertyProvider>(
        builder: (context, prov, _) {
          final myProps = prov.properties.where((p) => p.ownerId == ownerId).toList();
          if (myProps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_outlined, size: 64, color: colors.outline),
                  const SizedBox(height: 16),
                  Text('No properties assigned',
                      style: TextStyle(color: colors.outline, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Contact your landlord to be linked to properties',
                      style: TextStyle(color: colors.outline, fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myProps.length,
            itemBuilder: (_, i) {
              final prop = myProps[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colors.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.business, color: colors.primary),
                  ),
                  title: Text(prop.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${prop.city}, ${prop.state}',
                      style: const TextStyle(fontSize: 12)),
                  trailing: Chip(
                    label: Text('${prop.totalUnits} units',
                        style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                  ),
                  onTap: () {
                    Navigator.push(context,
                      MaterialPageRoute(
                        builder: (_) => PropertyDetailScreen(propertyId: prop.id!),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRevenueTab(ColorScheme colors, ThemeData theme) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revenue')),
      body: Consumer<PaymentProvider>(
        builder: (context, prov, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: _revenueCard('Total Collected', 'KSH ${_formatKsh(prov.totalCollected)}', Colors.green.shade700, Icons.trending_up)),
                  const SizedBox(width: 12),
                  Expanded(child: _revenueCard('Total Due', 'KSH ${_formatKsh(prov.totalDue)}', Colors.orange.shade700, Icons.trending_down)),
                ],
              ),
              const SizedBox(height: 16),
              _buildRevenueChart(colors, theme),
              const SizedBox(height: 16),
              Text('Payment History',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (prov.payments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('No payments recorded',
                        style: TextStyle(color: colors.outline)),
                  ),
                )
              else
                ...prov.payments.reversed.take(20).map((p) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        p.status == 'completed' ? Icons.check_circle : Icons.pending,
                        color: p.status == 'completed' ? Colors.green : Colors.orange,
                      ),
                      title: Text('KSH ${_formatKsh(p.amount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${p.paymentDate} • ${p.paymentType}',
                          style: const TextStyle(fontSize: 11)),
                      trailing: Text(p.status,
                          style: TextStyle(
                              fontSize: 12,
                              color: p.status == 'completed'
                                  ? Colors.green
                                  : Colors.orange)),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _revenueCard(String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab(ColorScheme colors, ThemeData theme) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Consumer<ExpenseProvider>(
        builder: (context, expProv, _) {
          final ownerId = _getOwnerId();
          final propertyProv = context.watch<PropertyProvider>();
          final paymentProv = context.watch<PaymentProvider>();
          final myProps = propertyProv.properties.where((p) => p.ownerId == ownerId).toList();

          double totalExpenses = expProv.getTotalExpenses();
          double totalIncome = paymentProv.totalCollected;
          double netProfit = totalIncome - totalExpenses;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Profit & Loss Summary',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _revenueCard('Income', 'KSH ${_formatKsh(totalIncome)}', Colors.green, Icons.arrow_upward)),
                  const SizedBox(width: 8),
                  Expanded(child: _revenueCard('Expenses', 'KSH ${_formatKsh(totalExpenses)}', Colors.red, Icons.arrow_downward)),
                  const SizedBox(width: 8),
                  Expanded(child: _revenueCard('Net Profit', 'KSH ${_formatKsh(netProfit)}', netProfit >= 0 ? Colors.blue : Colors.red, Icons.account_balance)),
                ],
              ),
              const SizedBox(height: 16),
              _buildExpenseBreakdown(colors, expProv),
              const SizedBox(height: 16),
              Text('Property Breakdown',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...myProps.map((prop) {
                return FutureBuilder<Map<String, dynamic>>(
                  future: _db.getProfitLoss(prop.id!),
                  builder: (context, snap) {
                    final pl = snap.data ?? {};
                    final income = (pl['total_income'] as num?)?.toDouble() ?? 0;
                    final expenses = (pl['total_expenses'] as num?)?.toDouble() ?? 0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colors.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.business, color: colors.primary, size: 20),
                        ),
                        title: Text(prop.name,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Income: KSH ${_formatKsh(income)} | Expenses: KSH ${_formatKsh(expenses)}',
                            style: const TextStyle(fontSize: 11)),
                        trailing: Text('KSH ${_formatKsh(income - expenses)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: income >= expenses ? Colors.green : Colors.red)),
                      ),
                    );
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExpenseBreakdown(ColorScheme colors, ExpenseProvider expProv) {
    final categories = expProv.categoryTotals;
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Expense by Category',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: categories.asMap().entries.map((e) {
                          final total = categories.fold<double>(0, (s, c) =>
                              s + ((c['total'] as num?)?.toDouble() ?? 0));
                          final value = (e.value['total'] as num?)?.toDouble() ?? 0;
                          final pct = total > 0 ? value / total : 0.0;
                          return PieChartSectionData(
                            value: value,
                            title: '${(pct * 100).toInt()}%',
                            color: _pieColors[e.key % _pieColors.length],
                            radius: 40,
                            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: categories.take(5).map((c) {
                      final idx = categories.indexOf(c);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: _pieColors[idx % _pieColors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('${c['category']}',
                                style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatKsh(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

const List<Color> _pieColors = [
  Colors.blue,
  Colors.red,
  Colors.orange,
  Colors.green,
  Colors.purple,
  Colors.teal,
  Colors.cyan,
  Colors.amber,
];
