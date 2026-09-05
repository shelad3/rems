import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/repositories/maintenance_repository.dart';
import '../../../data/models/maintenance_ticket_model.dart';
import '../widgets/ticket_card.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_state.dart';

class TenantTicketsScreen extends ConsumerWidget {
  const TenantTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/create-ticket'),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const EmptyStateWidget(title: 'Please log in');
          return StreamBuilder<List<MaintenanceTicketModel>>(
            stream: ref.watch(maintenanceRepositoryProvider).getTicketsByTenant(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ShimmerLoading();
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final tickets = snapshot.data ?? [];
              if (tickets.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.build_outlined,
                  title: 'No maintenance requests',
                  subtitle: 'Tap + to report an issue',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: tickets.length,
                itemBuilder: (_, i) => TicketCard(ticket: tickets[i]),
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
