import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/routes/navigation.dart';
import '../../../data/services/auth_service.dart';
import '../../../features/wallet/providers/wallet_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../widgets/update_check_tile.dart';

class CaretakerProfileScreen extends ConsumerWidget {
  const CaretakerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: userAsync.when(
        data: (user) => _buildProfile(context, ref, user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, WidgetRef ref, UserModel? user) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.success.withAlpha(25),
            child: Text(
              Helpers.getInitials(user?.fullName ?? '?'),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.success),
            ),
          ),
          const SizedBox(height: 12),
          Text(user?.fullName ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(user?.email ?? '', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('CARETAKER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
          ),
          const SizedBox(height: 24),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _Row(icon: Icons.phone_outlined, label: 'Phone', value: user?.phone ?? ''),
                const Divider(),
                _Row(icon: Icons.location_on_outlined, label: 'County', value: user?.county ?? 'Not set'),
                const Divider(),
                _Row(icon: Icons.badge_outlined, label: 'Status', value: (user?.status ?? '').toUpperCase()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: AppColors.primary),
              title: const Text('Wallet'),
              subtitle: Text(
                ref.watch(currentWalletProvider).value == null
                    ? 'KES 0.00'
                    : 'Balance: ${Helpers.formatCurrency(ref.watch(currentWalletProvider).value!.balance)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigation.push(context, AppRoutes.wallet),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: const UpdateCheckTile(),
          ),
          const SizedBox(height: 16),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                await ref.read(authServiceProvider).signOut();
                ref.invalidate(currentUserProvider);
                if (context.mounted) {
                  Navigation.pushClearingStack(context, AppRoutes.welcome);
                }
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }
}
