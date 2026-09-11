import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/property_assignment_model.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/property_assignment_repository.dart';
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

final _involvedAssignmentsProvider = StreamProvider<List<PropertyAssignmentModel>>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(propertyAssignmentRepositoryProvider).streamInvolving(uid);
});

class AssignmentRequestsScreen extends ConsumerWidget {
  const AssignmentRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Assignment Requests'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Requests'),
              Tab(text: 'Incoming'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OutgoingTab(),
            _IncomingTab(),
          ],
        ),
      ),
    );
  }
}

class _OutgoingTab extends ConsumerWidget {
  const _OutgoingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider).valueOrNull?.uid ?? '';
    final assignmentsAsync = ref.watch(_involvedAssignmentsProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _createRequest(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('New Assignment Request'),
            ),
          ),
        ),
        Expanded(
          child: assignmentsAsync.when(
            loading: () => const ShimmerLoading(),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (assignments) {
              final mine = assignments
                  .where((a) => a.requesterId == uid)
                  .toList();
              if (mine.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.outbox_outlined,
                  title: 'No requests sent',
                  subtitle: 'Request an owner or manager for your property',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: mine.length,
                itemBuilder: (_, i) => _AssignmentCard(
                  assignment: mine[i],
                  isTarget: false,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _IncomingTab extends ConsumerWidget {
  const _IncomingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider).valueOrNull?.uid ?? '';
    final assignmentsAsync = ref.watch(_involvedAssignmentsProvider);
    return assignmentsAsync.when(
      loading: () => const ShimmerLoading(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (assignments) {
        final incoming =
            assignments.where((a) => a.targetUserId == uid).toList();
        if (incoming.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.inbox_outlined,
            title: 'Nothing incoming',
            subtitle: 'You have no assignment requests',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: incoming.length,
          itemBuilder: (_, i) => _AssignmentCard(
            assignment: incoming[i],
            isTarget: true,
          ),
        );
      },
    );
  }
}

class _AssignmentCard extends ConsumerWidget {
  final PropertyAssignmentModel assignment;
  final bool isTarget;
  const _AssignmentCard({required this.assignment, required this.isTarget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider).valueOrNull?.uid ?? '';
    final isAdmin =
        ref.watch(currentUserProvider).valueOrNull?.role == 'admin';
    final isPending = assignment.status == 'pending';
    final isAccepted = assignment.status == 'accepted';
    final canAccept = isTarget && isPending;
    final canApprove =
        isAccepted && (isAdmin || assignment.requesterId == uid);

    final title = assignment.type == 'owner_assignment'
        ? 'Assign an Owner'
        : 'Assign a Manager';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                _StatusBadge(status: assignment.status),
              ],
            ),
            const SizedBox(height: 6),
            Text('Property: ${assignment.propertyId}',
                style: const TextStyle(color: AppColors.textSecondary)),
            if (assignment.message.isNotEmpty)
              Text('"${assignment.message}"',
                  style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            if (canAccept)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _accept(context, ref),
                  icon: const Icon(Icons.thumb_up_outlined, size: 18),
                  label: const Text('Accept'),
                ),
              ),
            if (canApprove) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _approve(context, ref),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Approve & Apply'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _reject(context, ref),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Reject'),
                ),
              ),
            ],
            if (isPending && !isTarget)
              Center(
                child: TextButton(
                  onPressed: () => _cancel(context, ref),
                  child: const Text('Cancel request'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    await ref.read(propertyAssignmentRepositoryProvider).update(
          assignment.assignmentId,
          {'status': 'accepted'},
        );
    if (context.mounted) {
      Helpers.showSnackBar(context, 'Request accepted');
    }
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final reviewerId = ref.read(currentUserProvider).valueOrNull?.uid;
    try {
      await ref.read(propertyRepositoryProvider).applyAssignment(
        assignmentId: assignment.assignmentId,
        propertyId: assignment.propertyId,
        type: assignment.type,
        userId: assignment.type == 'owner_assignment'
            ? assignment.targetUserId
            : assignment.targetUserId,
        reviewedBy: reviewerId,
      );
      if (context.mounted) {
        Helpers.showSnackBar(context, 'Assignment applied');
      }
    } catch (e) {
      if (context.mounted) {
        Helpers.showSnackBar(context, 'Failed to apply: $e', isError: true);
      }
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    await ref.read(propertyAssignmentRepositoryProvider).update(
          assignment.assignmentId,
          {
            'status': 'rejected',
            'reviewedAt': Timestamp.now(),
          },
        );
    if (context.mounted) {
      Helpers.showSnackBar(context, 'Request rejected');
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    await ref.read(propertyAssignmentRepositoryProvider).update(
          assignment.assignmentId,
          {
            'status': 'rejected',
            'notes': 'Cancelled by requester',
          },
        );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.error,
      'accepted' => AppColors.info,
      _ => AppColors.warning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(fontSize: 11, color: color)),
    );
  }
}

Future<void> _createRequest(BuildContext context, WidgetRef ref) async {
  final uid = ref.read(currentUserProvider).valueOrNull?.uid;
  if (uid == null) return;

  final props = await ref.read(_myPropsProvider.future).catchError((_) => <PropertyModel>[]);
  if (props.isEmpty) {
    if (context.mounted) {
      Helpers.showSnackBar(context, 'No managed properties to assign from',
          isError: true);
    }
    return;
  }

  final typeController = ValueNotifier<String>('manager_assignment');
  String? propertyId = props.first.propertyId;
  String? targetId;
  String message = '';

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        final role = typeController.value == 'owner_assignment' ? 'owner' : 'manager';
        return FutureBuilder<List<UserModel>>(
          future: ref.read(userRepositoryProvider).getUsersByRole(role),
          builder: (context, snapshot) {
            final targets = snapshot.data ?? const <UserModel>[];
            return AlertDialog(
              title: const Text('New Assignment Request'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: typeController.value,
                      decoration:
                          const InputDecoration(labelText: 'Role to assign'),
                      items: const [
                        DropdownMenuItem(
                            value: 'manager_assignment',
                            child: Text('Assign a Manager')),
                        DropdownMenuItem(
                            value: 'owner_assignment',
                            child: Text('Assign an Owner')),
                      ],
                      onChanged: (v) {
                        typeController.value = v ?? 'manager_assignment';
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: propertyId,
                      decoration: const InputDecoration(labelText: 'Property'),
                      items: props
                          .map((p) => DropdownMenuItem(
                              value: p.propertyId, child: Text(p.name)))
                          .toList(),
                      onChanged: (v) => propertyId = v,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Target $role'),
                      items: targets
                          .where((u) => u.uid != uid)
                          .map((u) => DropdownMenuItem(
                              value: u.uid, child: Text(u.fullName)))
                          .toList(),
                      onChanged: (v) => targetId = v,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => message = v,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'Message (optional)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: targetId == null || propertyId == null
                      ? null
                      : () {
                          ref
                              .read(propertyAssignmentRepositoryProvider)
                              .create(PropertyAssignmentModel(
                                assignmentId: FirebaseFirestore.instance
                                    .collection('property_assignments')
                                    .doc()
                                    .id,
                                propertyId: propertyId!,
                                requesterId: uid,
                                targetUserId: targetId!,
                                type: typeController.value,
                                message: message,
                              ));
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('Send Request'),
                ),
              ],
            );
          },
        );
      },
    ),
  );
}