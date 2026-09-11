import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/request_repository.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/repositories/maintenance_repository.dart';
import '../../../data/models/access_request_model.dart';
import '../../../data/models/maintenance_ticket_model.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/unit_model.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/screens/notification_center_screen.dart';
import '../../../widgets/request_card.dart';

class CaretakerDashboardScreen extends ConsumerWidget {
  const CaretakerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Consumer(builder: (context, ref, _) {
            final unreadCount = ref.watch(unreadCountProvider);
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('$unreadCount', style: const TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
      body: userAsync.when(
        data: (user) => _buildContent(context, ref, user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, UserModel? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(),
          const SizedBox(height: 20),
          const Text('Pending Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _PendingRequestsPreview(),
          ),
          const SizedBox(height: 20),
          const Text('Find Caretaker Jobs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.work_outline, color: AppColors.success),
              title: const Text('Browse open caretaker jobs'),
              subtitle: const Text('Apply to properties looking for a caretaker',
                  style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, AppRoutes.caretakerJobs),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(_caretakerPropertiesProvider);
    final properties = propertiesAsync.valueOrNull ?? const <PropertyModel>[];

    var pending = 0;
    for (final p in properties) {
      pending += ref.watch(_pendingByPropertyProvider(p.propertyId)).valueOrNull?.length ?? 0;
    }

    return Row(
      children: [
        Expanded(child: _SummaryCard(
          icon: Icons.person_add_outlined,
          label: 'Pending',
          value: '$pending',
          color: AppColors.warning,
        )),
        const SizedBox(width: 12),
        Expanded(child: _SummaryCard(
          icon: Icons.currency_exchange,
          label: 'Unpaid',
          value: '0',
          color: AppColors.error,
        )),
        const SizedBox(width: 12),
        Expanded(child: _SummaryCard(
          icon: Icons.build_outlined,
          label: 'Tickets',
          value: '${_countOpenTickets(ref, properties)}',
          color: AppColors.info,
        )),
        const SizedBox(width: 12),
        Expanded(child: _SummaryCard(
          icon: Icons.home_outlined,
          label: 'Vacant',
          value: '${_countVacantUnits(ref, properties)}',
          color: AppColors.success,
        )),
      ],
    );
  }

  int _countOpenTickets(WidgetRef ref, List<PropertyModel> properties) {
    int count = 0;
    for (final p in properties) {
      final tickets = ref.watch(_openTicketsProvider(p.propertyId));
      count += tickets.valueOrNull?.length ?? 0;
    }
    return count;
  }

  int _countVacantUnits(WidgetRef ref, List<PropertyModel> properties) {
    int count = 0;
    for (final p in properties) {
      final units = ref.watch(_unitsByPropertyProvider(p.propertyId));
      count += units.valueOrNull?.where((u) => !u.occupied).length ?? 0;
    }
    return count;
  }
}

final _caretakerPropertiesProvider = StreamProvider<List<PropertyModel>>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(propertyRepositoryProvider).getPropertiesByCaretaker(uid);
});

final _pendingByPropertyProvider =
    StreamProvider.family<List<AccessRequestModel>, String>((ref, propertyId) {
  return ref.watch(requestRepositoryProvider).getPendingRequestsByProperty(propertyId);
});

final _openTicketsProvider = StreamProvider.family<List<MaintenanceTicketModel>, String>((ref, propertyId) {
  return ref.watch(maintenanceRepositoryProvider).getOpenTicketsByProperty(propertyId);
});

final _unitsByPropertyProvider = StreamProvider.family<List<UnitModel>, String>((ref, propertyId) {
  return ref.watch(propertyRepositoryProvider).getUnitsByProperty(propertyId);
});

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _SummaryCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _PendingRequestsPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(_caretakerPropertiesProvider);
    final all = <AccessRequestModel>[];
    for (final p in propertiesAsync.valueOrNull ?? const <PropertyModel>[]) {
      final requests = ref.watch(_pendingByPropertyProvider(p.propertyId)).valueOrNull;
      if (requests != null) {
        all.addAll(requests);
      }
    }
    all.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    if (all.isEmpty) {
      return const Center(child: Text('No pending requests', style: TextStyle(color: AppColors.textSecondary)));
    }
    final preview = all.length > 3 ? all.sublist(0, 3) : all;
    return ListView.builder(
      itemCount: preview.length,
      itemBuilder: (_, i) => RequestCard(
        request: preview[i],
        onTap: () => Navigator.pushNamed(context, AppRoutes.caretakerRequests),
      ),
    );
  }
}