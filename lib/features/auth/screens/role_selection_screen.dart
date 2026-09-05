import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_routes.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  final List<_RoleOption> _roles = const [
    _RoleOption(
      title: 'Tenant',
      subtitle: 'Find and manage your rental home',
      icon: Icons.person_outline,
      color: AppColors.primary,
    ),
    _RoleOption(
      title: 'Caretaker',
      subtitle: 'Manage properties and tenants',
      icon: Icons.engineering_outlined,
      color: AppColors.success,
    ),
    _RoleOption(
      title: 'Owner / Landlord',
      subtitle: 'Oversee your property portfolio',
      icon: Icons.business_outlined,
      color: AppColors.warning,
    ),
    _RoleOption(
      title: 'Property Manager',
      subtitle: 'Manage multiple properties',
      icon: Icons.admin_panel_settings_outlined,
      color: AppColors.secondary,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Role')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How will you use REMS?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select your role to personalize your experience',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.separated(
                itemCount: _roles.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final role = _roles[index];
                  return _RoleCard(
                    title: role.title,
                    subtitle: role.subtitle,
                    icon: role.icon,
                    color: role.color,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.register,
                      arguments: role.title.toLowerCase().contains('owner')
                          ? 'owner'
                          : role.title.toLowerCase().contains('manager')
                              ? 'manager'
                              : role.title.toLowerCase().contains('caretaker')
                                  ? 'caretaker'
                                  : 'tenant',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _RoleOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
