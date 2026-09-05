import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/repositories/payment_repository.dart';
import '../providers/owner_analytics_provider.dart';

class OwnerComparisonScreen extends ConsumerWidget {
  const OwnerComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(ownerPropertiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Compare Properties')),
      body: propertiesAsync.when(
        data: (properties) {
          if (properties.length < 2) {
            return const Center(
              child: Text('Add more properties to compare',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Property Comparison',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...properties.map((p) => _PropertyComparisonCard(property: p)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _PropertyComparisonCard extends ConsumerWidget {
  final PropertyModel property;
  const _PropertyComparisonCard({required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(_propertyPaymentsProvider(property.propertyId));

    return paymentsAsync.when(
      data: (payments) {
        final totalCollected = payments.fold<double>(0.0, (s, p) => s + p.amount);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(property.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Metric(label: 'Units', value: '${property.totalUnits}'),
                    const SizedBox(width: 16),
                    _Metric(label: 'Available', value: '${property.availableUnits}'),
                    const SizedBox(width: 16),
                    _Metric(label: 'Income', value: Helpers.formatCurrency(totalCollected)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(property.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
      error: (e, _) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

final _propertyPaymentsProvider = StreamProvider.family<List<PaymentModel>, String>((ref, propertyId) {
  return ref.read(paymentRepositoryProvider).getPaymentsByProperty(propertyId);
});

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
