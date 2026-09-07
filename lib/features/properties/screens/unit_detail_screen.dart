import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/unit_model.dart';
import '../../../data/models/access_request_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/repositories/request_repository.dart';
import '../../../data/repositories/audit_log_repository.dart';
import '../../../widgets/loading_widget.dart';
import 'add_unit_screen.dart';
import 'add_property_screen.dart';
import 'edit_unit_screen.dart';

class UnitDetailScreen extends ConsumerWidget {
  final PropertyModel property;
  const UnitDetailScreen({super.key, required this.property});

  bool _canManage(UserModel? user) {
    final role = user?.role;
    return role == 'owner' || role == 'manager' || role == 'admin';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final canManage = _canManage(user);
    return Scaffold(
      appBar: AppBar(
        title: Text(property.name),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Property',
              onPressed: () async {
                final changed = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddPropertyScreen(property: property),
                  ),
                );
                if (changed == true && context.mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
        ],
      ),
      body: StreamBuilder<List<UnitModel>>(
        stream: canManage
            ? ref.watch(propertyRepositoryProvider).getUnitsByProperty(property.propertyId)
            : ref.watch(propertyRepositoryProvider).getAvailableUnits(property.propertyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerLoading();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final units = snapshot.data ?? [];
          if (units.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.home_outlined, size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  const Text('No units yet', style: TextStyle(color: AppColors.textSecondary)),
                  if (canManage) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _openAddUnit(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add the first unit'),
                    ),
                  ],
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: units.length,
            itemBuilder: (_, i) => _UnitDetailCard(
              unit: units[i],
              canManage: canManage,
              onEdit: canManage ? () => _openEditUnit(context, units[i]) : null,
              onDelete: canManage
                  ? () => _deleteUnit(context, ref, units[i])
                  : null,
            ),
          );
        },
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openAddUnit(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Unit'),
            )
          : null,
    );
  }

  void _openAddUnit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddUnitScreen(property: property)),
    );
  }

  void _openEditUnit(BuildContext context, UnitModel unit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditUnitScreen(property: property, unit: unit),
      ),
    );
  }

  void _deleteUnit(BuildContext context, WidgetRef ref, UnitModel unit) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Unit?'),
        content: Text('Delete unit ${unit.unitNumber} from this property?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      final repo = ref.read(propertyRepositoryProvider);
      await repo.deleteUnit(unit.unitId);
      await repo.updateUnitsCount(
        property.propertyId,
        (property.totalUnits - 1).clamp(0, 1000000).toInt(),
        (property.availableUnits - (unit.occupied ? 0 : 1)).clamp(0, 1000000).toInt(),
      );
      final actor = ref.read(authServiceProvider).currentUser?.uid ?? '';
      ref.read(auditLogRepositoryProvider).log(
        actorId: actor,
        action: 'unit_deleted',
        targetType: 'unit',
        targetId: unit.unitId,
        metadata: {'propertyId': property.propertyId},
      );
      if (context.mounted) {
        Helpers.showSnackBar(context, 'Unit deleted');
      }
    });
  }
}

class _UnitDetailCard extends ConsumerWidget {
  final UnitModel unit;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _UnitDetailCard({
    required this.unit,
    this.canManage = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.home_outlined, color: AppColors.primary, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Unit ${unit.unitNumber}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('${unit.unitType} · ${unit.bedrooms} bedroom${unit.bedrooms > 1 ? 's' : ''}',
                          style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (unit.occupied)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('OCCUPIED',
                        style: TextStyle(fontSize: 10,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                _PriceColumn(label: 'Monthly Rent', amount: unit.rentAmount),
                const SizedBox(width: 32),
                _PriceColumn(label: 'Deposit', amount: unit.depositAmount),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _InfoChip(icon: Icons.merge_type, label: unit.unitType),
                const SizedBox(width: 8),
                _InfoChip(icon: Icons.bed_outlined, label: '${unit.bedrooms} Bed'),
              ],
            ),
            const SizedBox(height: 24),
            if (canManage)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      label: const Text('Delete', style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _requestAccess(context, ref),
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Request Access'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _requestAccess(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      Helpers.showSnackBar(context, 'Please log in first', isError: true);
      Navigator.pushNamed(context, AppRoutes.login);
      return;
    }
    final requestId = FirebaseFirestore.instance.collection('access_requests').doc().id;
    final request = AccessRequestModel(
      requestId: requestId,
      tenantId: user.uid,
      propertyId: unit.propertyId,
      unitId: unit.unitId,
      status: 'pending',
      tenantName: user.displayName,
      tenantEmail: user.email,
      desiredMoveInDate: DateTime.now().toString().split(' ')[0],
    );
    await ref.read(requestRepositoryProvider).createRequest(request);
    if (context.mounted) {
      Helpers.showSnackBar(context, 'Request submitted! Awaiting approval.');
    }
  }
}

class _PriceColumn extends StatelessWidget {
  final String label;
  final double amount;
  const _PriceColumn({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          Helpers.formatCurrency(amount),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
        ],
      ),
    );
  }
}