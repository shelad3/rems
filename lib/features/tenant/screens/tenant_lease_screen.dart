import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/repositories/lease_repository.dart';
import '../../../data/models/lease_model.dart';
import '../widgets/lease_card.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_state.dart';

class TenantLeaseScreen extends ConsumerWidget {
  const TenantLeaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Lease')),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const EmptyStateWidget(title: 'Please log in');
          return StreamBuilder<List<LeaseModel>>(
            stream: ref.watch(leaseRepositoryProvider).getLeasesByTenant(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ShimmerLoading();
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final leases = snapshot.data ?? [];
              if (leases.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.description_outlined,
                  title: 'No active lease',
                  subtitle: 'Your lease will appear here once approved',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: leases.length,
                itemBuilder: (_, i) => LeaseCard(
                  lease: leases[i],
                  onAcceptTerms: leases[i].termsAccepted
                      ? null
                      : () => _acceptTerms(context, ref, leases[i]),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _acceptTerms(BuildContext context, WidgetRef ref, LeaseModel lease) async {
    try {
      await ref.read(leaseRepositoryProvider).acceptLeaseTerms(lease.leaseId);
      if (context.mounted) {
        Helpers.showSnackBar(context, 'Lease terms accepted successfully');
      }
    } catch (e) {
      if (context.mounted) {
        Helpers.showSnackBar(context, 'Failed to accept terms: $e', isError: true);
      }
    }
  }
}
