import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/unit_model.dart';
import '../../../data/models/access_request_model.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/repositories/request_repository.dart';
import '../../../data/repositories/lease_repository.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_widget.dart';

final _myPropsProvider = StreamProvider<List<PropertyModel>>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid ?? '';
  final repo = ref.watch(propertyRepositoryProvider);
  if (uid.isEmpty) return const Stream.empty();
  return Stream.multi((controller) {
    final subs = [
      repo.getPropertiesByOwner(uid).listen(controller.add, onError: controller.addError),
      repo.getPropertiesByManager(uid).listen(controller.add, onError: controller.addError),
    ];
    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };
  });
});

final _pendingByPropertyProvider =
    StreamProvider.family<List<AccessRequestModel>, String>((ref, propertyId) {
  return ref.watch(requestRepositoryProvider).getPendingRequestsByProperty(propertyId);
});

final _unitProvider = StreamProvider.family<UnitModel?, String>((ref, unitId) {
  if (unitId.isEmpty) return Stream.value(null);
  return ref.watch(propertyRepositoryProvider).getUnitById(unitId);
});

class OwnerAccessRequestsScreen extends ConsumerWidget {
  const OwnerAccessRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access Requests')),
      body: ref.watch(_myPropsProvider).when(
        loading: () => const ShimmerLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (properties) {
          if (properties.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.home_work_outlined,
              title: 'No properties',
              subtitle: 'Add a property to receive access requests',
            );
          }
          properties.sort((a, b) => a.name.compareTo(b.name));
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: properties.length,
            itemBuilder: (_, i) => _PropertySection(property: properties[i]),
          );
        },
      ),
    );
  }
}

class _PropertySection extends ConsumerWidget {
  final PropertyModel property;
  const _PropertySection({required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(_pendingByPropertyProvider(property.propertyId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(property.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
        requestsAsync.when(
          loading: () => const ShimmerLoading(),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
          ),
          data: (requests) {
            if (requests.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('No pending requests',
                    style: TextStyle(color: AppColors.textSecondary)),
              );
            }
            return Column(
              children: [for (final r in requests) _RequestTile(request: r)],
            );
          },
        ),
      ],
    );
  }
}

class _RequestTile extends ConsumerWidget {
  final AccessRequestModel request;
  const _RequestTile({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitAsync = ref.watch(_unitProvider(request.unitId ?? ''));
    final unit = unitAsync.valueOrNull;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.tenantName ?? 'Tenant',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('PENDING',
                      style: TextStyle(fontSize: 10, color: AppColors.warning)),
                ),
              ],
            ),
            if (request.tenantEmail != null || request.tenantPhone != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  [request.tenantEmail, request.tenantPhone]
                      .where((e) => e != null && e.isNotEmpty)
                      .join(' · '),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            const Divider(height: 16),
            Row(
              children: [
                _InfoPill(label: 'Unit ${unit?.unitNumber ?? request.unitId ?? '?'}'),
                const SizedBox(width: 8),
                if (unit != null)
                  _InfoPill(label: Helpers.formatCurrency(unit.rentAmount)),
                if (request.desiredMoveInDate != null) ...[
                  const SizedBox(width: 8),
                  _InfoPill(label: 'Move-in: ${request.desiredMoveInDate}'),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approve(context, ref),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Approve & Create Lease'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _reject(context, ref),
                  icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                  tooltip: 'Reject',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final reviewerId = ref.read(currentUserProvider).valueOrNull?.uid;
    if (reviewerId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve this tenant?'),
        content: const Text(
            'This will create a lease, occupy the unit, and assign the tenant. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    try {
      await ref.read(leaseRepositoryProvider).approveRequest(
            request: request,
            reviewedBy: reviewerId,
          );
      if (context.mounted) {
        Helpers.showSnackBar(context, 'Tenant approved — lease created');
      }
    } catch (e) {
      if (context.mounted) {
        Helpers.showSnackBar(context, 'Approval failed: $e', isError: true);
      }
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reviewerId = ref.read(currentUserProvider).valueOrNull?.uid;
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;
    await ref.read(requestRepositoryProvider).updateRequest(request.requestId, {
      'status': 'rejected',
      'reviewedBy': reviewerId,
      'reviewedAt': Timestamp.now(),
      'notes': reason.isEmpty ? 'Rejected' : reason,
    });
    if (context.mounted) {
      Helpers.showSnackBar(context, 'Request rejected');
    }
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  const _InfoPill({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
    );
  }
}