import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/unit_model.dart';
import '../providers/payment_provider.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_state.dart';

class CaretakerPaymentsScreen extends ConsumerWidget {
  const CaretakerPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: StreamBuilder<List<PropertyModel>>(
        stream: ref.watch(propertyRepositoryProvider).getProperties(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerLoading();
          }
          final properties = snapshot.data ?? [];
          if (properties.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.home_work_outlined,
              title: 'No properties',
              subtitle: 'Contact admin to get property access',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: properties.length,
            itemBuilder: (_, i) => _PropertyPaymentCard(property: properties[i]),
          );
        },
      ),
    );
  }
}

class _PropertyPaymentCard extends ConsumerWidget {
  final PropertyModel property;
  const _PropertyPaymentCard({required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(property.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<List<UnitModel>>(
              stream: ref.watch(propertyRepositoryProvider).getUnitsByProperty(property.propertyId),
              builder: (context, snapshot) {
                final units = snapshot.data ?? [];
                final occupied = units.where((u) => u.occupied).toList();
                if (occupied.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('No occupied units', style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return Column(
                  children: occupied.map((unit) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.person_outline, color: AppColors.primary),
                    title: Text('Unit ${unit.unitNumber}'),
                    subtitle: Text('Tenant: ${unit.tenantId?.substring(0, 8) ?? 'Unknown'}'),
                    trailing: TextButton.icon(
                      onPressed: () => _showPaymentDialog(context, ref, unit),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Record'),
                    ),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, WidgetRef ref, UnitModel unit) {
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    String method = 'cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInnerState) => AlertDialog(
          title: const Text('Record Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Unit ${unit.unitNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: 'KES ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: method,
                  decoration: const InputDecoration(
                    labelText: 'Method',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'mpesa', child: Text('M-Pesa')),
                    DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                  ],
                  onChanged: (v) => setInnerState(() => method = v ?? 'cash'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reference (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text);
                if (amount == null || amount <= 0) return;
                await ref.read(paymentProvider.notifier).recordPayment(
                  tenantId: unit.tenantId ?? '',
                  propertyId: unit.propertyId,
                  unitId: unit.unitId,
                  amount: amount,
                  method: method,
                  reference: refCtrl.text,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  Helpers.showSnackBar(context, 'Payment recorded successfully');
                }
              },
              child: const Text('Record'),
            ),
          ],
        ),
      ),
    );
  }
}
