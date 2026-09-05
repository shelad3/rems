import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/repositories/request_repository.dart';
import '../../../data/models/access_request_model.dart';
import '../../../widgets/request_card.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_state.dart';

class TenantRequestsScreen extends ConsumerWidget {
  const TenantRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const EmptyStateWidget(title: 'Please log in');
          return StreamBuilder<List<AccessRequestModel>>(
            stream: ref.watch(requestRepositoryProvider).getRequestsByTenant(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ShimmerLoading();
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final requests = snapshot.data ?? [];
              if (requests.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.send_outlined,
                  title: 'No requests yet',
                  subtitle: 'Browse properties and request access',
                );
              }
              return ListView.builder(
                itemCount: requests.length,
                itemBuilder: (_, i) => RequestCard(request: requests[i]),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
