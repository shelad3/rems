import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/routes/app_routes.dart';
import '../features/subscriptions/providers/subscription_provider.dart';

class PremiumGate extends ConsumerWidget {
  final Widget child;
  final Widget? lockedOverlay;

  const PremiumGate({super.key, required this.child, this.lockedOverlay});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    if (isPremium) return child;

    return Stack(
      children: [
        child,
        if (lockedOverlay != null)
          lockedOverlay!
        else
          Positioned.fill(
            child: Container(
              color: Colors.black.withAlpha(100),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 48, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'Premium Feature',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upgrade to Premium to unlock this feature',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.upgrade),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Upgrade Now'),
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
