import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/maintenance_repository.dart';
import '../../../data/models/maintenance_ticket_model.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/screens/notification_center_screen.dart';
import '../../../widgets/ad_banner.dart';

class TenantHomeScreen extends ConsumerWidget {
  const TenantHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
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
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
      body: userAsync.when(
        data: (user) => _buildContent(context, user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserModel? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeCard(user: user),
          const SizedBox(height: 20),
          _QuickActions(),
          const SizedBox(height: 20),
          const AdBanner(),
          const SizedBox(height: 20),
          _CurrentResidence(user: user),
          const SizedBox(height: 20),
          _RecentActivity(),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final UserModel? user;
  const _WelcomeCard({this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
             'Welcome${user != null ? ', ${user!.fullName.split(' ').first}' : ''}!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your rental home is just a tap away',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statusBadge(user?.status ?? 'pending'),
              const SizedBox(width: 12),
              if (user?.subscriptionTier == 'free')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.white70),
                      SizedBox(width: 4),
                      Text('Free Plan', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = status == 'active' ? AppColors.success :
                 status == 'pending' ? AppColors.warning : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _ActionButton(
              icon: Icons.search_outlined,
              label: 'Find Property',
              onTap: () => Navigator.pushNamed(context, AppRoutes.tenantProperties),
            )),
            const SizedBox(width: 12),
            Expanded(child: _ActionButton(
              icon: Icons.payment_outlined,
              label: 'Pay Rent',
              onTap: () => Navigator.pushNamed(context, AppRoutes.tenantPayments),
            )),
            const SizedBox(width: 12),
            Expanded(child: _ActionButton(
              icon: Icons.build_outlined,
              label: 'Maintenance',
              onTap: () => Navigator.pushNamed(context, AppRoutes.tenantTickets),
            )),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentResidence extends StatelessWidget {
  final UserModel? user;
  const _CurrentResidence({this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Current Residence', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: user?.currentUnitId != null
              ? ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.home_outlined, color: AppColors.primary),
                  ),
                  title: const Text('Unit assigned'),
                  subtitle: Text('Property ID: ${user?.currentPropertyId ?? 'N/A'}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.tenantLease),
                )
              : SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.home_outlined, size: 48, color: AppColors.textHint),
                        const SizedBox(height: 8),
                        const Text('No unit assigned yet'),
                        const SizedBox(height: 4),
                        const Text('Browse properties to find your home', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.tenantProperties),
                          child: const Text('Browse Properties'),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _RecentActivity extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<List<MaintenanceTicketModel>>(
              stream: ref.watch(maintenanceRepositoryProvider).getTicketsByTenant(user.uid),
              builder: (context, snapshot) {
                final tickets = snapshot.data ?? [];
                if (tickets.isEmpty) {
                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: const Icon(Icons.check_circle_outline, color: AppColors.success),
                      title: const Text('No recent activity'),
                      subtitle: const Text('Your activities will appear here'),
                    ),
                  );
                }
                return Column(
                  children: tickets.take(3).map((t) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.build_outlined, color: t.status == 'resolved' ? AppColors.success : AppColors.warning),
                      title: Text(t.category, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(t.status.replaceAll('_', ' ')),
                      trailing: Text(Helpers.timeAgo(t.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ),
                  )).toList(),
                );
              },
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
