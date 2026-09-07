import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/audit_log_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/routes/navigation.dart';
import '../../../data/services/push_service.dart';
import '../../../data/models/user_model.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_state.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searchController.text.isEmpty && !_searchFocused
            ? const Text('Users')
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Users',
            onPressed: () => setState(() => _searchFocused = true),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                Navigation.pushClearingStack(context, AppRoutes.welcome);
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_searchFocused ? 64 : 0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _searchFocused
                ? Padding(
                    key: const ValueKey('search'),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchFocused = false);
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                : const SizedBox(height: 0),
          ),
        ),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: ref.watch(userRepositoryProvider).streamAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerLoading();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          var users = snapshot.data ?? [];
          final query = _searchController.text.trim().toLowerCase();
          if (query.isNotEmpty) {
            users = users.where((u) =>
                u.fullName.toLowerCase().contains(query) ||
                u.email.toLowerCase().contains(query)).toList();
          }
          if (users.isEmpty) {
            return const EmptyStateWidget(title: 'No users found');
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (_, i) => _UserTile(user: users[i]),
          );
        },
      ),
    );
  }

  bool _searchFocused = false;
}

class _UserTile extends ConsumerWidget {
  final UserModel user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _roleColor.withAlpha(25),
          child: Text(
            Helpers.getInitials(user.fullName),
            style: TextStyle(color: _roleColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(user.fullName),
        subtitle: Text('${user.role} · ${user.email}'),
        trailing: _statusChip(user.status),
        onTap: () => _showUserDetail(context, ref, user),
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = status == 'active' ? AppColors.success :
                 status == 'pending' ? AppColors.warning : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Color get _roleColor {
    switch (user.role) {
      case 'admin': return AppColors.error;
      case 'owner': return AppColors.warning;
      case 'caretaker': return AppColors.success;
      default: return AppColors.primary;
    }
  }

  void _showUserDetail(BuildContext context, WidgetRef ref, UserModel user) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(user.email, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            _info('Status', user.status),
            _info('Role', user.role),
            _info('Phone', user.phone),
            _info('County', user.county ?? 'N/A'),
            _info('Plan', user.subscriptionTier),
            if (user.status == 'pending') ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref.read(userRepositoryProvider).updateUser(user.uid, {'status': 'rejected'});
                        _logAudit(ref, 'user_rejected', user);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(userRepositoryProvider).updateUser(user.uid, {'status': 'active'});
                        _logAudit(ref, 'user_approved', user);
                        ref.read(pushServiceProvider).send(
                          recipientUid: user.uid,
                          title: 'Account approved',
                          body: 'Your REM S account is now active. Welcome aboard!',
                          data: {'type': 'account'},
                        );
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
            if (_isSuperAdmin(ref)) ...[
              const SizedBox(height: 20),
              if (user.role == 'admin')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(userRepositoryProvider).updateUser(
                        user.uid,
                        {'role': 'tenant', 'status': 'active'},
                      );
                      _logAudit(ref, 'admin_removed', user);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.person_remove, size: 18),
                    label: const Text('Remove Admin'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(userRepositoryProvider).updateUser(
                        user.uid,
                        {'role': 'admin', 'status': 'active'},
                      );
                      _logAudit(ref, 'admin_granted', user);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.admin_panel_settings, size: 18),
                    label: const Text('Make Admin'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isSuperAdmin(WidgetRef ref) {
    return ref.read(authServiceProvider).currentUser?.email == superAdminEmail;
  }

  void _logAudit(WidgetRef ref, String action, UserModel target) {
    final actor = ref.read(authServiceProvider).currentUser?.uid ?? '';
    ref.read(auditLogRepositoryProvider).log(
          actorId: actor,
          action: action,
          targetType: 'user',
          targetId: target.uid,
          metadata: {
            'email': target.email,
            'role': target.role,
          },
        );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
