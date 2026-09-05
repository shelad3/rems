import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/unit_model.dart';
import '../../../widgets/property_card.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_state.dart';

final _propertyListProvider = StreamProvider<List<PropertyModel>>((ref) {
  return ref.watch(propertyRepositoryProvider).getProperties();
});

final _unitsListProvider = StreamProvider<List<UnitModel>>((ref) {
  return ref.watch(propertyRepositoryProvider).streamAllUnits();
});

class TenantPropertiesScreen extends ConsumerStatefulWidget {
  const TenantPropertiesScreen({super.key});

  @override
  ConsumerState<TenantPropertiesScreen> createState() => _TenantPropertiesScreenState();
}

class _TenantPropertiesScreenState extends ConsumerState<TenantPropertiesScreen> {
  final _searchController = TextEditingController();
  String _selectedChip = 'All';
  double? _minRent;
  double? _maxRent;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesUnitFilter(UnitModel unit, List<UnitModel> propertyUnits) {
    if (unit.occupied) return false;
    if (_selectedChip == 'Bedsitter' && !(unit.unitType.toLowerCase().contains('bedsitter') || unit.bedrooms == 0)) {
      return false;
    }
    if (_selectedChip == '1 Bedroom' && unit.bedrooms != 1) return false;
    if (_selectedChip == '2 Bedroom' && unit.bedrooms != 2) return false;
    if (_selectedChip == 'Furnished' && !unit.unitType.toLowerCase().contains('furnished')) return false;
    if (_minRent != null && unit.rentAmount < _minRent!) return false;
    if (_maxRent != null && unit.rentAmount > _maxRent!) return false;
    return true;
  }

  List<PropertyModel> _applyFilters(
    List<PropertyModel> properties,
    List<UnitModel> allUnits,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final unitsByProperty = <String, List<UnitModel>>{};
    for (final unit in allUnits) {
      unitsByProperty.putIfAbsent(unit.propertyId, () => []).add(unit);
    }

    final hasFilter = _selectedChip != 'All' || _minRent != null || _maxRent != null;

    return properties.where((property) {
      if (query.isNotEmpty) {
        final name = property.name.toLowerCase();
        final location = property.location.toLowerCase();
        final county = property.county.toLowerCase();
        if (!name.contains(query) && !location.contains(query) && !county.contains(query)) {
          return false;
        }
      }
      if (!hasFilter) return true;
      final units = unitsByProperty[property.propertyId] ?? const <UnitModel>[];
      return units.any((unit) => _matchesUnitFilter(unit, units));
    }).toList();
  }

  void _showFilters() {
    final minController = TextEditingController(text: _minRent?.toString() ?? '');
    final maxController = TextEditingController(text: _maxRent?.toString() ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            const Text('Monthly Rent Range (KES)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Min'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _minRent = double.tryParse(minController.text.trim());
                        _maxRent = double.tryParse(maxController.text.trim());
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(_propertyListProvider);
    final unitsAsync = ref.watch(_unitsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Properties'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search properties...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: _showFilters,
                      tooltip: 'Filters',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final label in ['All', 'Bedsitter', '1 Bedroom', '2 Bedroom', 'Furnished'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: _selectedChip == label,
                            onSelected: (_) => setState(() => _selectedChip = label),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: propertiesAsync.when(
              loading: () => const ShimmerLoading(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (allProperties) => unitsAsync.when(
                loading: () => const ShimmerLoading(),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (allUnits) {
                  final filtered = _applyFilters(allProperties, allUnits);
                  if (filtered.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.home_work_outlined,
                      title: 'No properties match',
                      subtitle: 'Adjust your search or filters',
                    );
                  }
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => PropertyCard(
                      property: filtered[index],
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.unitDetail,
                          arguments: filtered[index],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}