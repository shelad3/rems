import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../features/updates/providers/update_provider.dart';

class UpdateCheckTile extends ConsumerWidget {
  const UpdateCheckTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(updateControllerProvider);
    return ListTile(
      leading: const Icon(Icons.system_update_alt_outlined, color: AppColors.primary),
      title: const Text('Check for updates'),
      subtitle: const Text('Fetch the latest version from GitHub'),
      trailing: controller.checking
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: controller.checking
          ? null
          : () => controller.checkAndPrompt(context: context, manual: true),
    );
  }
}