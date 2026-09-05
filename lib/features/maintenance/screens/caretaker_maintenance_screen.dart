import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/repositories/maintenance_repository.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/models/maintenance_ticket_model.dart';
import '../../../data/models/property_model.dart';
import '../widgets/ticket_card.dart';
import '../providers/maintenance_provider.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_state.dart';

class CaretakerMaintenanceScreen extends ConsumerStatefulWidget {
  const CaretakerMaintenanceScreen({super.key});

  @override
  ConsumerState<CaretakerMaintenanceScreen> createState() => _CaretakerMaintenanceScreenState();
}

class _CaretakerMaintenanceScreenState extends ConsumerState<CaretakerMaintenanceScreen> {
  String _statusFilter = 'open';
  String? _selectedPropertyId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterMenu(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPropertySelector(),
          _buildStatusTabs(),
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

  Widget _buildStatusTabs() {
    const statuses = ['open', 'acknowledged', 'in_progress', 'resolved'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: statuses.map((s) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(s.replaceAll('_', ' ').toUpperCase()),
              selected: _statusFilter == s,
              onSelected: (_) => setState(() => _statusFilter = s),
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildTicketList() {
    if (_selectedPropertyId == null) {
      return const EmptyStateWidget(
        icon: Icons.filter_alt_outlined,
        title: 'Select a property',
        subtitle: 'Choose a property to view maintenance tickets',
      );
    }

    return StreamBuilder<List<MaintenanceTicketModel>>(
      stream: ref.watch(maintenanceRepositoryProvider).getTicketsByProperty(_selectedPropertyId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerLoading();
        }
        final allTickets = snapshot.data ?? [];
        final tickets = allTickets
            .where((t) => _statusFilter == 'all' || t.status == _statusFilter)
            .toList();

        if (tickets.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.task_alt,
            title: 'No tickets',
            subtitle: 'All maintenance tickets are resolved',
          );
        }

        return ListView.builder(
          itemCount: tickets.length,
          itemBuilder: (_, i) => TicketCard(
            ticket: tickets[i],
            onTap: () => _showTicketActions(context, tickets[i]),
          ),
        );
      },
    );
  }

  void _showFilterMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter by Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...[
              'all', 'open', 'acknowledged', 'in_progress', 'resolved',
            ].map((s) => ListTile(
              leading: Radio<String>(
                value: s,
                groupValue: _statusFilter,
                onChanged: (v) {
                  setState(() => _statusFilter = v ?? 'open');
                  Navigator.pop(ctx);
                },
              ),
              title: Text(s.replaceAll('_', ' ').toUpperCase()),
              onTap: () {
                setState(() => _statusFilter = s);
                Navigator.pop(ctx);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showTicketActions(BuildContext context, MaintenanceTicketModel ticket) {
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
            if (ticket.status == 'acknowledged') ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(maintenanceProvider.notifier).updateTicketStatus(ticket.ticketId, 'in_progress');
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Work'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.info),
                ),
              ),
            ],
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
            if (ticket.status == 'resolved') ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Helpers.showSnackBar(context, 'Ticket resolved');
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Details'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
