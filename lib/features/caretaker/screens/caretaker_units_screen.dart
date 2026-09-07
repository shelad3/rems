import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/unit_model.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../widgets/unit_card.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_state.dart';
import 'caretaker_unit_detail_screen.dart';

class CaretakerUnitsScreen extends ConsumerStatefulWidget {
  const CaretakerUnitsScreen({super.key});

  @override
  ConsumerState<CaretakerUnitsScreen> createState() => _CaretakerUnitsScreenState();
}

class _CaretakerUnitsScreenState extends ConsumerState<CaretakerUnitsScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Units'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _filter,
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'all', child: Text('All Units')),
              const PopupMenuItem(value: 'vacant', child: Text('Vacant')),
              const PopupMenuItem(value: 'occupied', child: Text('Occupied')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<PropertyModel>>(
        stream: ref
            .watch(propertyRepositoryProvider)
            .getPropertiesByCaretaker(
                ref.watch(currentUserProvider).valueOrNull?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerLoading();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final properties = snapshot.data ?? [];
          if (properties.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.home_work_outlined,
              title: 'No properties assigned',
              subtitle: 'Contact admin to get property access',
            );
          }
          return ListView(
            children: properties
                .map((property) => _PropertyUnitList(property: property, filter: _filter))
                .toList(),
          );
        },
      ),
    );
  }
}

class _PropertyUnitList extends ConsumerWidget {
  final PropertyModel property;
  final String filter;
  const _PropertyUnitList({required this.property, required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            property.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        StreamBuilder<List<UnitModel>>(
          stream: ref.watch(propertyRepositoryProvider).getUnitsByProperty(property.propertyId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ShimmerLoading(itemCount: 2);
            }
            if (snapshot.hasError) {
              return const SizedBox();
            }
            final units = snapshot.data ?? [];
            final filtered = filter == 'all'
                ? units
                : units.where((u) => filter == 'vacant' ? !u.occupied : u.occupied).toList();
            if (filtered.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No units match filter', style: TextStyle(color: AppColors.textSecondary)),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
                itemBuilder: (_, i) => UnitCard(
                  unit: filtered[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CaretakerUnitDetailScreen(
                        unit: filtered[i],
                        propertyId: property.propertyId,
                        propertyName: property.name,
                      ),
                    ),
                  ),
                ),
            );
          },
        ),
      ],
    );
  }
}
