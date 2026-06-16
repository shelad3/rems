import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/lease_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../services/firestore_service.dart';
import '../profile/profile_screen.dart';
import '../payments/payment_list_screen.dart';
import '../payments/pay_rent_screen.dart';
import '../maintenance/add_maintenance_screen.dart';
import '../documents/document_list_screen.dart';

class TenantShell extends StatefulWidget {
  const TenantShell({super.key});

  @override
  State<TenantShell> createState() => _TenantShellState();
}

class _TenantShellState extends State<TenantShell> {
  int _currentIndex = 0;
  final _firestore = FirestoreService.instance;
  final _fmt = NumberFormat.currency(symbol: 'KES ');
  final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final auth = context.watch<AuthProvider>();

    final screens = [
      _buildHomeDashboard(colorScheme, auth),
      const PaymentListScreen(),
      _buildMyLeaseTab(colorScheme, auth),
      _buildMaintenanceTab(colorScheme, auth),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          HapticFeedback.selectionClick();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Payments',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'My Lease',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'Maintenance',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ===================== TAB 0: HOME DASHBOARD =====================

  Widget _buildHomeDashboard(ColorScheme colors, AuthProvider auth) {
    final uid = auth.user?.uid ?? '';
    final tenantName = auth.user?.name ?? 'Tenant';
    final tenantId = auth.user?.tenantId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, ${tenantName.split(' ').first}'),
        actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Messages coming soon')),
                );
              },
              tooltip: 'Messages',
            ),
          ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: tenantId != null
            ? _firestore.db.collection('tenants').doc(tenantId.toString()).snapshots()
            : null,
        builder: (context, tenantSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: _firestore.tenantLeaseStream(uid),
            builder: (context, leaseSnap) {
              final lease = leaseSnap.hasData && leaseSnap.data!.docs.isNotEmpty
                  ? leaseSnap.data!.docs.first.data() as Map<String, dynamic>
                  : null;
              final rentAmount = (lease?['rentAmount'] as num?)?.toDouble() ?? 0;
              final isActive = lease?['isActive'] == true;

              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<PaymentProvider>().loadPayments();
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Rent Status Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isActive ? Icons.check_circle : Icons.home_outlined,
                                  color: isActive ? Colors.green : Colors.grey,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(isActive ? 'Rent Due' : 'No Active Lease',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      if (isActive) ...[
                                        const SizedBox(height: 4),
                                        Text('${_fmt.format(rentAmount)}/mo',
                                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.primary)),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isActive)
                                  FilledButton.icon(
                                    onPressed: () {
                                      final leaseProvider = context.read<LeaseProvider>();
                                      final tenantProvider = context.read<TenantProvider>();
                                      final tenant = tenantProvider.tenants
                                          .where((t) => t.id == tenantId)
                                          .firstOrNull;
                                      final activeLease = leaseProvider.leases
                                          .where((l) => l.tenantId == tenantId && l.isActive)
                                          .firstOrNull;
                                      if (tenant != null && activeLease != null) {
                                        Navigator.push(context,
                                          MaterialPageRoute(builder: (_) => PayRentScreen(
                                            leaseId: activeLease.id!,
                                            tenantId: tenant.id!,
                                            rentAmount: activeLease.rentAmount,
                                            tenantName: tenant.name,
                                            unitNumber: 'Unit ${activeLease.unitId}',
                                          )),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.payments, size: 18),
                                    label: const Text('Pay'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Actions Grid
                    Text('Quick Actions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _actionCard(Icons.payments, 'Pay Rent', Colors.green, () {
                          setState(() => _currentIndex = 1);
                        })),
                        const SizedBox(width: 8),
                        Expanded(child: _actionCard(Icons.build, 'Report Issue', Colors.orange, () {
                          setState(() => _currentIndex = 3);
                        })),
                        const SizedBox(width: 8),
                        Expanded(child: _actionCard(Icons.description, 'My Lease', Colors.blue, () {
                          setState(() => _currentIndex = 2);
                        })),
                        const SizedBox(width: 8),
                        Expanded(child: _actionCard(Icons.notifications, 'Messages', Colors.purple, () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Messages coming soon')),
                          );
                        })),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Payment History (recent 3)
                    Consumer<PaymentProvider>(
                      builder: (context, pp, _) {
                        final tenantPayments = pp.payments
                            .where((p) => p.tenantId == tenantId)
                            .toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Recent Payments',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                if (tenantPayments.length > 3)
                                  TextButton(
                                    onPressed: () => setState(() => _currentIndex = 1),
                                    child: const Text('See All'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (tenantPayments.isEmpty)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey[300]),
                                        const SizedBox(height: 8),
                                        Text('No payments yet', style: TextStyle(color: Colors.grey[500])),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...tenantPayments.reversed.take(3).map((p) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      dense: true,
                                      leading: Icon(
                                        p.status == 'Paid' ? Icons.check_circle : Icons.schedule,
                                        color: p.status == 'Paid' ? Colors.green : Colors.orange,
                                      ),
                                      title: Text(_fmt.format(p.amount),
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('${p.paymentMethod} • ${_dateFmt.format(p.paymentDate)}',
                                          style: const TextStyle(fontSize: 12)),
                                      trailing: Text(p.status,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: p.status == 'Paid' ? Colors.green : Colors.orange,
                                          )),
                                    ),
                                  )),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Maintenance Tickets Summary
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore.tenantMaintenanceStream(uid),
                      builder: (context, snap) {
                        if (!snap.hasData || snap.data!.docs.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final tickets = snap.data!.docs;
                        final openTickets = tickets.where((d) =>
                            (d.data() as Map)['status'] != 'resolved').length;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Open Maintenance Tickets',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                                  child: Text('$openTickets',
                                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                ),
                                title: const Text('Open Requests'),
                                subtitle: const Text('Tap to view details'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => setState(() => _currentIndex = 3),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // (Messages section coming soon)
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _actionCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700]), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== TAB 2: MY LEASE =====================

  Widget _buildMyLeaseTab(ColorScheme colors, AuthProvider auth) {
    final uid = auth.user?.uid ?? '';
    final tenantId = auth.user?.tenantId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Lease'),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined),
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const DocumentListScreen()),
            ),
            tooltip: 'Documents',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _firestore.getLeaseByTenant(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final lease = snapshot.data;

          if (lease == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No active lease',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Once your application is approved,\nyour lease will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _currentIndex = 0);
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Browse Available Units'),
                  ),
                ],
              ),
            );
          }

          final rentAmount = (lease['rentAmount'] as num?)?.toDouble() ?? 0;
          final deposit = (lease['deposit'] as num?)?.toDouble();
          final startDate = lease['startDate'] as String?;
          final endDate = lease['endDate'] as String?;
          final unitId = lease['unitId'] as String? ?? '';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Lease Overview Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description, color: colors.primary, size: 24),
                          const SizedBox(width: 8),
                          Text('Lease Agreement',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Active', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _leaseRow(Icons.home_outlined, 'Unit', unitId),
                      _leaseRow(Icons.monetization_on_outlined, 'Monthly Rent', _fmt.format(rentAmount)),
                      if (deposit != null)
                        _leaseRow(Icons.security_outlined, 'Security Deposit', _fmt.format(deposit)),
                      if (startDate != null)
                        _leaseRow(Icons.play_circle_outline, 'Start Date', startDate),
                      if (endDate != null)
                        _leaseRow(Icons.event_outlined, 'End Date', endDate),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Payment Summary
              Consumer<PaymentProvider>(
                builder: (context, pp, _) {
                  final leasePayments = pp.payments
                      .where((p) => p.tenantId == tenantId)
                      .toList();
                  final totalPaid = leasePayments
                      .where((p) => p.status == 'Paid')
                      .fold<double>(0, (sum, p) => sum + p.amount);
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Payment Summary',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _statBox('Total Paid', _fmt.format(totalPaid), Colors.green)),
                              const SizedBox(width: 8),
                              Expanded(child: _statBox('Monthly', _fmt.format(rentAmount), colors.primary)),
                              const SizedBox(width: 8),
                              Expanded(child: _statBox('Payments', '${leasePayments.length}', Colors.blue)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => setState(() => _currentIndex = 1),
                  icon: const Icon(Icons.payments),
                  label: const Text('Pay Rent'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DocumentListScreen()),
                  ),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('View Lease Documents'),
                ),
              ),
              const SizedBox(height: 24),

              // Lease Timeline
              Text('Lease Timeline',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (startDate != null)
                _timelineItem(
                  Icons.check_circle,
                  Colors.green,
                  'Lease Started',
                  startDate,
                  isFirst: true,
                ),
              if (endDate != null) ...[
                _timelineItem(
                  Icons.event,
                  Colors.blue,
                  'Lease Ends',
                  endDate,
                ),
                _timelineItem(
                  Icons.autorenew,
                  Colors.orange,
                  'Renewal',
                  '30 days before end date',
                  isLast: true,
                ),
              ],

              const SizedBox(height: 24),

              // Late Fees & Terms
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lease Terms',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _termRow('Late Fee', '5% of monthly rent after 5th'),
                      _termRow('Notice Period', '30 days written notice'),
                      _termRow('Allowed Pets', 'With deposit only'),
                      _termRow('Subletting', 'Not allowed'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _leaseRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 12),
          SizedBox(width: 120, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _timelineItem(IconData icon, Color color, String title, String subtitle,
      {bool isFirst = false, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(width: 2, height: 8, color: Colors.grey[300]),
            Icon(icon, color: color, size: 22),
            if (!isLast)
              Expanded(child: Container(width: 2, height: 40, color: Colors.grey[300])),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _termRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 6, color: Colors.grey[400]),
          const SizedBox(width: 8),
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  // ===================== TAB 3: MAINTENANCE =====================

  Widget _buildMaintenanceTab(ColorScheme colors, AuthProvider auth) {
    final uid = auth.user?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddMaintenanceScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.tenantMaintenanceStream(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tickets = snapshot.data!.docs;
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.build_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No maintenance requests',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Report an issue and we will fix it!',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AddMaintenanceScreen()),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Report Issue'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (_, i) {
              final d = tickets[i];
              final data = d.data() as Map<String, dynamic>;
              final status = data['status'] as String? ?? 'pending';
              final color = status == 'resolved' ? Colors.green
                  : status == 'in_progress' ? Colors.orange
                  : Colors.grey;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Icon(
                      status == 'resolved' ? Icons.check_circle
                          : status == 'in_progress' ? Icons.build
                          : Icons.schedule,
                      color: color, size: 20,
                    ),
                  ),
                  title: Text(data['issue'] as String? ?? 'Request',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['description'] != null && (data['description'] as String).isNotEmpty)
                        Text(data['description'] as String, maxLines: 1,
                            overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(status.replaceAll('_', ' '),
                                style: TextStyle(fontSize: 10, color: color)),
                          ),
                          const SizedBox(width: 8),
                          Text(data['priority'] as String? ?? 'Medium',
                              style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        ],
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
                  onTap: () {
                    Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AddMaintenanceScreen()),
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
}
