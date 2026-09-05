import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/maintenance_ticket_model.dart';
import '../../../data/models/property_model.dart';
import '../../../data/repositories/maintenance_repository.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../features/maintenance/providers/maintenance_provider.dart';
import '../../../widgets/maintenance_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_widget.dart';

class CaretakerTasksScreen extends ConsumerStatefulWidget {
  const CaretakerTasksScreen({super.key});

  @override
  ConsumerState<CaretakerTasksScreen> createState() => _CaretakerTasksScreenState();
}

class _CaretakerTasksScreenState extends ConsumerState<CaretakerTasksScreen> {
  String? _selectedPropertyId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Tasks'),
      ),
      body: Column(
        children: [
          _buildPropertySelector(),
          Expanded(child: _buildTicketList()),
        ],
      ),
    );
  }

  Widget _buildPropertySelector() {
    return StreamBuilder<List<PropertyModel>>(
      stream: ref.watch(propertyRepositoryProvider).getProperties(),
      builder: (context, snapshot) {
        final properties = snapshot.data ?? [];
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: DropdownButtonFormField<String>(
            value: _selectedPropertyId,
            decoration: const InputDecoration(
              labelText: 'Property',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('All Properties')),
              ...properties.map((p) => DropdownMenuItem(value: p.propertyId, child: Text(p.name))),
            ],
            onChanged: (v) => setState(() => _selectedPropertyId = v),
          ),
        );
      },
    );
  }

  Widget _buildTicketList() {
    if (_selectedPropertyId == null) {
      return const EmptyStateWidget(
        icon: Icons.filter_alt_outlined,
        title: 'Select a property',
        subtitle: 'Choose a property to view maintenance tasks',
      );
    }

    return StreamBuilder<List<MaintenanceTicketModel>>(
      stream: ref.watch(maintenanceRepositoryProvider).getOpenTicketsByProperty(_selectedPropertyId!),
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
            icon: Icons.task_alt,
            title: 'All caught up',
            subtitle: 'No open maintenance tasks',
          );
        }
        final sorted = List<MaintenanceTicketModel>.from(tickets)
          ..sort((a, b) {
            const order = {'emergency': 0, 'high': 1, 'medium': 2, 'low': 3};
            return (order[a.priority] ?? 4).compareTo(order[b.priority] ?? 4);
          });
        return ListView.builder(
          itemCount: sorted.length,
          itemBuilder: (_, i) => MaintenanceCard(
            ticket: sorted[i],
            onTap: () => _showTicketActions(sorted[i]),
          ),
        );
      },
    );
  }

  void _showTicketActions(MaintenanceTicketModel ticket) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ticket.category.toUpperCase(), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(ticket.description, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Divider(height: 24),
            if (ticket.status == 'open')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(maintenanceProvider.notifier).updateTicketStatus(ticket.ticketId, 'acknowledged');
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Acknowledge'),
                ),
              ),
            if (ticket.status == 'in_progress') ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(maintenanceProvider.notifier).updateTicketStatus(ticket.ticketId, 'resolved');
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark Resolved'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
