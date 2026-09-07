import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/models/property_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../widgets/property_card.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_state.dart';

final _myPropertiesProvider = StreamProvider.autoDispose.family<List<PropertyModel>, String>(
  (ref, uid) {
    final repo = ref.watch(propertyRepositoryProvider);
    if (uid.isEmpty) return repo.streamAllProperties();
    return Stream.multi((controller) {
      final subs = [
        repo.getPropertiesByOwner(uid).listen(controller.add, onError: controller.addError),
        repo.getPropertiesByManager(uid).listen(controller.add, onError: controller.addError),
      ];
      controller.onCancel = () {
        for (final s in subs) {
          s.cancel();
        }
      };
    });
  },
);

class OwnerPropertiesScreen extends ConsumerWidget {
  const OwnerPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void openAddProperty() => Navigator.pushNamed(context, AppRoutes.addProperty);

    final uid = ref.watch(currentUserProvider).valueOrNull?.uid ?? '';

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
      body: ref.watch(_myPropertiesProvider(uid)).when(
        loading: () => const ShimmerLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (properties) {
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
