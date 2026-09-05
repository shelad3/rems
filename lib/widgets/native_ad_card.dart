import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../features/subscriptions/providers/subscription_provider.dart';

class NativeAdCard extends ConsumerWidget {
  const NativeAdCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.adBackground,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.apartment, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Sponsored', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                  const SizedBox(height: 2),
                  const Text('Find your dream home',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const Text('Browse premium listings',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Learn More',
                  style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
