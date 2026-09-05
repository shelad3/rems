import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/repositories/wallet_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../providers/subscription_provider.dart';

class UpgradeScreen extends ConsumerWidget {
  const UpgradeScreen({super.key});

  Future<void> _upgrade(
      BuildContext context, WidgetRef ref, String tier, double price) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Upgrade'),
        content: Text(
          'Upgrade to $tier for ${Helpers.formatCurrency(price)}/month?\n\n'
          'Payment will be charged to your wallet balance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pay'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final uid = user.uid;
    final balance = ref.read(currentWalletProvider).value?.balance ?? 0;
    if (balance < price) {
      Helpers.showSnackBar(
        context,
        'Insufficient wallet balance. Deposit first.',
        isError: true,
      );
      return;
    }

    final adminUid = await ref.read(walletRepositoryProvider).primaryAdminUid();
    if (adminUid == null) {
      Helpers.showSnackBar(context, 'No admin account found', isError: true);
      return;
    }

    final debited =
        await ref.read(walletRepositoryProvider).debit(
              uid: uid,
              amount: price,
              source: 'premium',
              referenceId: user.uid,
              description: '$tier subscription',
            );
    if (debited == null) {
      Helpers.showSnackBar(context, 'Purchase failed', isError: true);
      return;
    }

    await ref.read(walletRepositoryProvider).credit(
          uid: adminUid,
          amount: price,
          source: 'premium',
          referenceId: user.uid,
          description: 'Premium payment from ${user.email}',
        );

    await ref.read(authServiceProvider).updateProfile({'subscriptionTier': tier});
    ref.invalidate(currentUserProvider);
    if (context.mounted) {
      Helpers.showSnackBar(
        context,
        'Upgraded to $tier. Payment sent to admin wallet.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade Plan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          const Text('Choose the plan that\'s right for you',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          _PlanCard(
            title: 'Free',
            price: 'KES 0',
            period: '/mo',
            color: AppColors.textSecondary,
            features: const [
              '1 Property',
              'Basic analytics',
              'Ads supported',
              'Email support',
            ],
            isCurrent: !isPremium,
            onUpgrade: null,
          ),
          const SizedBox(height: 16),
          _PlanCard(
            title: 'Premium',
            price: 'KES 999',
            period: '/mo',
            color: AppColors.warning,
            features: const [
              'Unlimited properties',
              'Advanced analytics & charts',
              'No ads',
              'PDF export & reports',
              'Smart notifications',
              'Priority support',
            ],
            isCurrent: isPremium,
            onUpgrade: isPremium
                ? null
                : () => _upgrade(context, ref, 'premium', 999),
            recommended: true,
          ),
          const SizedBox(height: 16),
          _PlanCard(
            title: 'Enterprise',
            price: 'KES 2,999',
            period: '/mo',
            color: AppColors.primary,
            features: const [
              'Everything in Premium',
              'Custom branding',
              'API access',
              'Dedicated account manager',
              'AI assistant',
              'Custom integrations',
            ],
            isCurrent: false,
            onUpgrade: () => _upgrade(context, ref, 'enterprise', 2999),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final Color color;
  final List<String> features;
  final bool isCurrent;
  final VoidCallback? onUpgrade;
  final bool recommended;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.color,
    required this.features,
    this.isCurrent = false,
    this.onUpgrade,
    this.recommended = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: recommended ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    title == 'Free' ? Icons.free_breakfast : Icons.workspace_premium,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(price, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                          Text(period, style: const TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (recommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                    child: const Text('BEST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
              ],
            ),
            const Divider(height: 24),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(f, style: const TextStyle(fontSize: 14)),
                ],
              ),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: isCurrent
                  ? OutlinedButton(
                      onPressed: null,
                      child: const Text('Current Plan'),
                    )
                  : ElevatedButton(
                      onPressed: onUpgrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('${title == 'Free' ? 'Stay' : 'Upgrade'} $title'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
