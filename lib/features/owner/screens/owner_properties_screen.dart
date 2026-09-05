import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/models/property_model.dart';
import '../../../widgets/property_card.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_state.dart';

class OwnerPropertiesScreen extends ConsumerWidget {
  const OwnerPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void openAddProperty() => Navigator.pushNamed(context, AppRoutes.addProperty);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Properties'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: openAddProperty,
            tooltip: 'Add Property',
          ),
        ],
      ),
      body: StreamBuilder<List<PropertyModel>>(
        stream: ref.watch(propertyRepositoryProvider).streamAllProperties(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerLoading();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final properties = snapshot.data ?? [];
          if (properties.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.home_work_outlined,
              title: 'No properties yet',
              subtitle: 'Add your first property to get started',
              actionLabel: 'Add Property',
              onAction: openAddProperty,
            );
          }
          return ListView.builder(
            itemCount: properties.length,
            itemBuilder: (_, i) => PropertyCard(
              property: properties[i],
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.unitDetail,
                arguments: properties[i],
              ),
            ),
          );
        },
      ),
    );
  }
}
