import 'package:flutter/material.dart';
import '../core/routes/app_routes.dart';

class PremiumBanner extends StatelessWidget {
  final String? message;
  final String? ctaText;

  const PremiumBanner({super.key, this.message, this.ctaText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, color: Colors.white, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Go Premium',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  message ?? 'Unlock advanced features',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.upgrade),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepOrange,
            ),
            child: Text(ctaText ?? 'Upgrade'),
          ),
        ],
      ),
    );
  }
}
