import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../features/subscriptions/providers/subscription_provider.dart';
import '../data/services/auth_service.dart';

class AdBanner extends ConsumerWidget {
  const AdBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final flags = ref.watch(featureFlagProvider).valueOrNull ?? {};
    final adsEnabled = flags['ads_enabled'] ?? true;

    if (user?.subscriptionTier == 'premium' || !adsEnabled) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 60),
      decoration: BoxDecoration(
        color: AppColors.adBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ads_click, size: 16, color: AppColors.primary.withAlpha(150)),
            const SizedBox(width: 8),
            Text('Ad Space', style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withAlpha(180))),
          ],
        ),
      ),
    );
  }
}
