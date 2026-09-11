import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/caretaker_application_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/repositories/caretaker_application_repository.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_widget.dart';

final _openPositionsProvider = StreamProvider<List<PropertyModel>>((ref) {
  return ref
      .watch(propertyRepositoryProvider)
      .streamAllProperties()
      .map((props) => props
          .where((p) => p.status == 'active' && p.caretakerHiringOpen)
          .toList());
});

final _myApplicationsProvider = StreamProvider<List<CaretakerApplicationModel>>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(caretakerApplicationRepositoryProvider).streamByCaretaker(uid);
});

class CaretakerJobsScreen extends ConsumerWidget {
  const CaretakerJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Caretaker Jobs'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Open Positions'),
              Tab(text: 'My Applications'),
            ],
          ),
        ),
        body: user == null
            ? const EmptyStateWidget(
                icon: Icons.person_off_outlined,
                title: 'Not signed in',
                subtitle: 'Please sign in to view jobs',
              )
            : TabBarView(
                children: [
                  _OpenPositions(user: user),
                  _MyApplications(user: user),
                ],
              ),
      ),
    );
  }
}

class _OpenPositions extends ConsumerWidget {
  final UserModel user;
  const _OpenPositions({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positionsAsync = ref.watch(_openPositionsProvider);
    final applicationsAsync = ref.watch(_myApplicationsProvider);

    return positionsAsync.when(
      loading: () => const ShimmerLoading(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (positions) {
        final pendingByPropertyId = (applicationsAsync.valueOrNull ??
                const <CaretakerApplicationModel>[])
            .where((a) => a.status == 'pending')
            .map((a) => a.propertyId)
            .toSet();

        if (positions.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.work_off_outlined,
            title: 'No open positions',
            subtitle: 'Owners have not opened any caretaker hiring yet',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: positions.length,
          itemBuilder: (_, i) {
            final p = positions[i];
            final alreadyCaretaker = p.caretakerId == user.uid;
            final applied = pendingByPropertyId.contains(p.propertyId);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.home_work_outlined,
                              color: AppColors.success),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              Text('${p.county} · ${p.location}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (p.startingRent > 0) ...[
                      const SizedBox(height: 12),
                      Text('Starts at ${Helpers.formatCurrency(p.startingRent)}/month',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: alreadyCaretaker
                          ? const OutlinedButton(
                              onPressed: null,
                              child: Text('Assigned to you'),
                            )
                          : applied
                              ? const OutlinedButton(
                                  onPressed: null,
                                  child: Text('Application submitted'),
                                )
                              : ElevatedButton.icon(
                                  onPressed: () => _apply(context, ref, p),
                                  icon: const Icon(Icons.send_outlined, size: 18),
                                  label: const Text('Apply'),
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _apply(
      BuildContext context, WidgetRef ref, PropertyModel property) async {
    final messageController = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply as Caretaker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${property.name} · ${property.county}'),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Short message (optional)',
                hintText: 'Why are you a good fit?',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, messageController.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    messageController.dispose();
    if (message == null) return;

    final uid = ref.read(currentUserProvider).valueOrNull?.uid;
    if (uid == null) return;

    final repo = ref.read(caretakerApplicationRepositoryProvider);
    if (await repo.hasPendingApplication(uid, property.propertyId)) {
      if (context.mounted) {
        Helpers.showSnackBar(context, 'You have already applied to this property');
      }
      return;
    }

    final application = CaretakerApplicationModel(
      applicationId: FirebaseFirestore.instance
          .collection('caretaker_applications')
          .doc()
          .id,
      propertyId: property.propertyId,
      caretakerId: uid,
      message: message,
    );
    try {
      await repo.create(application);
      if (context.mounted) {
        Helpers.showSnackBar(context, 'Application submitted');
      }
    } catch (e) {
      if (context.mounted) {
        Helpers.showSnackBar(context, 'Failed to apply: $e', isError: true);
      }
    }
  }
}

class _MyApplications extends ConsumerWidget {
  final UserModel user;
  const _MyApplications({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(_myApplicationsProvider);
    return applicationsAsync.when(
      loading: () => const ShimmerLoading(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (applications) {
        if (applications.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.send_outlined,
            title: 'No applications yet',
            subtitle: 'Apply for a caretaker job from the Open Positions tab',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: applications.length,
          itemBuilder: (_, i) {
            final app = applications[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                isThreeLine: true,
                title: Text(
                  app.status.toUpperCase(),
                  style: TextStyle(
                    color: switch (app.status) {
                      'approved' => AppColors.success,
                      'rejected' => AppColors.error,
                      _ => AppColors.warning,
                    },
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Property: ${app.propertyId}'),
                    if (app.message.isNotEmpty) Text('"${app.message}"'),
                    Text('Applied ${Helpers.timeAgo(app.createdAt)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                trailing: app.status == 'pending'
                    ? TextButton(
                        onPressed: () =>
                            _withdraw(context, ref, app),
                        child: const Text('Withdraw'),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _withdraw(
      BuildContext context, WidgetRef ref, CaretakerApplicationModel app) async {
    await ref
        .read(caretakerApplicationRepositoryProvider)
        .update(app.applicationId, {
      'status': 'rejected',
      'notes': 'Withdrawn by applicant',
    });
  }
}