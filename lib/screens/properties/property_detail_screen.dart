import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/property_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/maintenance_tile.dart';
import 'add_edit_property_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final int propertyId;

  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  Map<String, dynamic>? _propertyWithOwner;
  List<Map<String, dynamic>> _maintenanceRequests = [];
  bool _loading = true;
  final _firestore = FirestoreService.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final propertyDocs = await _firestore.propertiesRef
          .where('propertyId', isEqualTo: widget.propertyId)
          .limit(1)
          .get();
      if (propertyDocs.docs.isNotEmpty) {
        final doc = propertyDocs.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        _propertyWithOwner = <String, dynamic>{'id': doc.id}
          ..addAll(data);
        final ownerId = data['ownerId'];
        if (ownerId != null) {
          final ownerDoc = await _firestore.db.collection('owners')
              .doc(ownerId.toString())
              .get();
          if (ownerDoc.exists) {
            _propertyWithOwner!['owner_name'] =
                (ownerDoc.data() as Map<String, dynamic>)['name'];
          }
        }
      }

      final maintenanceSnap = await _firestore.db.collection('maintenance')
          .where('propertyId', isEqualTo: widget.propertyId.toString())
          .get();
      _maintenanceRequests = maintenanceSnap.docs.map((d) {
        final m = <String, dynamic>{'id': d.id};
        final data = d.data() as Map<String, dynamic>?;
        if (data != null) m.addAll(data);
        return m;
      }).toList();

      if (mounted) {
        setState(() => _loading = false);
        context.read<PropertyProvider>().loadUnitsByProperty(widget.propertyId);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = context.watch<PropertyProvider>();
    final maintenanceProvider = context.watch<MaintenanceProvider>();

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final property = _propertyWithOwner;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(property?['name'] as String? ?? 'Property'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                final prop = propertyProvider.getPropertyById(widget.propertyId);
                if (prop != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditPropertyScreen(property: prop),
                    ),
                  );
                }
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Units'),
              Tab(text: 'Maintenance'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverview(property, propertyProvider),
            _buildUnits(propertyProvider),
            _buildMaintenance(maintenanceProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(Map<String, dynamic>? property, PropertyProvider provider) {
    final properties = provider.properties;
    final prop = properties.where((p) => p.id == widget.propertyId).toList();
    if (prop.isEmpty) {
      return const Center(child: Text('Property not found'));
    }
    final p = prop.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        p.type == 'Commercial'
                            ? Icons.business
                            : Icons.home,
                        size: 32,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text(p.type,
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  _infoRow(Icons.person, 'Owner',
                      property?['owner_name'] as String? ?? 'Unknown'),
                  _infoRow(Icons.location_on,
                      'Address',
                      '${p.address}, ${p.city}, ${p.state} ${p.zip}'),
                  _infoRow(Icons.category, 'Type', p.type),
                  _infoRow(
                      Icons.apartment, 'Total Units', '${p.totalUnits}'),
                  _infoRow(Icons.pie_chart, 'Occupied',
                      '${provider.getOccupiedUnits(p.id!)} units'),
                  if (p.notes.isNotEmpty) ...[
                    const Divider(),
                    _infoRow(Icons.notes, 'Notes', p.notes),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _actionCard(
                  context,
                  Icons.add_business,
                  'Add Unit',
                  Colors.green,
                  () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionCard(
                  context,
                  Icons.build,
                  'Add Request',
                  Colors.orange,
                  () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnits(PropertyProvider provider) {
    final units = provider.units;
    return units.isEmpty
        ? const Center(child: Text('No units added yet'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: units.length,
            itemBuilder: (context, index) {
              final unit = units[index];
              final currencyFormat =
                  NumberFormat.currency(symbol: '\$');
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: unit.isOccupied
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.door_front_door,
                      color: unit.isOccupied ? Colors.green : Colors.grey,
                    ),
                  ),
                  title: Text('Unit ${unit.unitNumber}'),
                  subtitle: Text(
                    '${unit.bedrooms}BR / ${unit.bathrooms}BA'
                    '${unit.squareFeet > 0 ? ' • ${unit.squareFeet.toStringAsFixed(0)} sqft' : ''}'
                    ' • ${currencyFormat.format(unit.rentAmount)}/mo',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: unit.isOccupied
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      unit.isOccupied ? 'Occupied' : 'Vacant',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            unit.isOccupied ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildMaintenance(MaintenanceProvider provider) {
    if (_maintenanceRequests.isEmpty) {
      return const Center(child: Text('No maintenance requests'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _maintenanceRequests.length,
      itemBuilder: (context, index) {
        final item = _maintenanceRequests[index];
        return MaintenanceTile(
          title: item['title'] as String? ?? '',
          tenantName: item['tenant_name'] as String? ?? 'Unknown',
          unitNumber: item['unit_number'] as String? ?? '',
          priority: item['priority'] as String? ?? 'Medium',
          status: item['status'] as String? ?? 'Pending',
          createdAt: DateTime.parse(item['created_at'] as String),
          onTap: () {},
        );
      },
    );
  }
}
