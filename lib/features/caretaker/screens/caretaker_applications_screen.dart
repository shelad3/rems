import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/caretaker_application_model.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/caretaker_application_repository.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_widget.dart';

final _myPropertiesProvider = StreamProvider<List<PropertyModel>>((ref) {
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

final _pendingAppsPropertyProvider =
    StreamProvider.family<List<CaretakerApplicationModel>, String>((ref, propertyId) {
  return ref
      .watch(caretakerApplicationRepositoryProvider)
      .streamPendingForProperty(propertyId);
});

final _applicantProvider =
    StreamProvider.family<UserModel?, String>((ref, uid) {
  return ref.watch(userRepositoryProvider).getUserById(uid);
});

class CaretakerApplicationsScreen extends ConsumerWidget {
  const CaretakerApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Caretaker Applications')),
      body: ref.watch(_myPropertiesProvider).when(
        loading: () => const ShimmerLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (properties) {
          if (properties.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.home_work_outlined,
              title: 'No properties',
              subtitle: 'Add a property to receive caretaker applications',
            );
          }
          final withHiring = properties
              .where((p) => p.caretakerHiringOpen || p.caretakerId == null)
              .toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: withHiring.length,
            itemBuilder: (_, i) => _PropertySection(property: withHiring[i]),
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
    final appsAsync = ref.watch(_pendingAppsPropertyProvider(property.propertyId));
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: const Icon(Icons.home_work_outlined, color: AppColors.primary),
        title: Text(
          property.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Hiring: ${property.caretakerHiringOpen ? 'Open' : 'Closed'}',
          style: TextStyle(
            fontSize: 12,
            color: property.caretakerHiringOpen ? AppColors.success : AppColors.textSecondary,
          ),
        ),
        children: [
          appsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
            ),
            data: (apps) {
              if (apps.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No pending applications',
                      style: TextStyle(color: AppColors.textSecondary)),
                );
              }
              return Column(
                children: [for (final app in apps) _ApplicationTile(app: app)],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ApplicationTile extends ConsumerWidget {
  final CaretakerApplicationModel app;
  const _ApplicationTile({required this.app});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicantAsync = ref.watch(_applicantProvider(app.caretakerId));
    final applicant = applicantAsync.valueOrNull;
    return ListTile(
      isThreeLine: true,
      leading: CircleAvatar(
        child: Text(
          applicant?.fullName.isNotEmpty == true
              ? applicant!.fullName[0].toUpperCase()
              : '?',
        ),
      ),
      title: Text(applicant?.fullName.isNotEmpty == true
          ? applicant!.fullName
          : app.caretakerId),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (app.message.isNotEmpty)
            Text('"${app.message}"', maxLines: 2, overflow: TextOverflow.ellipsis),
          Text(
            'Applied ${Helpers.timeAgo(app.createdAt)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
            tooltip: 'Approve & Assign',
            onPressed: () => _approve(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
            tooltip: 'Reject',
            onPressed: () => _reject(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final propertyId = app.propertyId;
    final reviewerId = ref.read(currentUserProvider).valueOrNull?.uid;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve application?'),
        content: Text(
            'This will assign the caretaker to the property and close hiring for it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Approve & Assign'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await ref.read(propertyRepositoryProvider).appointCaretaker(
        propertyId: propertyId,
        caretakerId: app.caretakerId,
        applicationId: app.applicationId,
        reviewedBy: reviewerId,
      );
      if (context.mounted) {
        Helpers.showSnackBar(context, 'Caretaker assigned');
      }
    } catch (e) {
      if (context.mounted) {
        Helpers.showSnackBar(context, 'Failed to approve: $e', isError: true);
      }
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reviewerId = ref.read(currentUserProvider).valueOrNull?.uid;
    try {
      await ref.read(caretakerApplicationRepositoryProvider).update(
        app.applicationId,
        {
          'status': 'rejected',
          'reviewedBy': reviewerId,
          'reviewedAt': Timestamp.now(),
        },
      );
      if (context.mounted) {
        Helpers.showSnackBar(context, 'Application rejected');
      }
    } catch (e) {
      if (context.mounted) {
        Helpers.showSnackBar(context, 'Failed to reject: $e', isError: true);
      }
    }
  }
}