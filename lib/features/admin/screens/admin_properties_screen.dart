import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/models/property_model.dart';
import '../../../widgets/property_card.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_state.dart';

class AdminPropertiesScreen extends ConsumerWidget {
  const AdminPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Properties')),
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
            return const EmptyStateWidget(title: 'No properties registered');
          }
          return ListView.builder(
            itemCount: properties.length,
            itemBuilder: (_, i) => PropertyCard(property: properties[i]),
          );
        },
      ),
    );
  }
}
