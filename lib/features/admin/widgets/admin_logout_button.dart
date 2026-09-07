import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/routes/navigation.dart';
import '../../../data/services/auth_service.dart';

class AdminLogoutButton extends ConsumerWidget {
  const AdminLogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.logout, color: AppColors.error),
      tooltip: 'Sign Out',
      onPressed: () async {
        await ref.read(authServiceProvider).signOut();
        ref.invalidate(currentUserProvider);
        if (context.mounted) {
          Navigation.pushClearingStack(context, AppRoutes.welcome);
        }
      },
    );
  }
}