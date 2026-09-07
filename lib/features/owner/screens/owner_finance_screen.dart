import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../features/payments/widgets/payment_card.dart';

final _financePeriodProvider = StateProvider<FinancePeriod>((ref) => FinancePeriod.thisMonth);

enum FinancePeriod { thisMonth, lastMonth, thisQuarter, thisYear, allTime }

extension FinancePeriodLabel on FinancePeriod {
  String get label {
    switch (this) {
      case FinancePeriod.thisMonth: return 'This Month';
      case FinancePeriod.lastMonth: return 'Last Month';
      case FinancePeriod.thisQuarter: return 'This Quarter';
      case FinancePeriod.thisYear: return 'This Year';
      case FinancePeriod.allTime: return 'All Time';
    }
  }
}

class OwnerFinanceScreen extends ConsumerWidget {
  const OwnerFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(_ownerPropertiesProvider);
    final period = ref.watch(_financePeriodProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<FinancePeriod>(
                value: period,
                isDense: true,
                items: FinancePeriod.values.map((p) => DropdownMenuItem(
                  value: p,
                  child: Text(p.label, style: const TextStyle(fontSize: 13)),
                )).toList(),
                onChanged: (v) {
                  if (v != null) ref.read(_financePeriodProvider.notifier).state = v;
                },
              ),
            ),
          ),
        ],
      ),
      body: propertiesAsync.when(
        data: (properties) {
          if (properties.isEmpty) {
            return const Center(child: Text('No properties found', style: TextStyle(color: AppColors.textSecondary)));
          }
          return _FinanceBody(properties: properties, period: period);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _FinanceBody extends ConsumerWidget {
  final List<PropertyModel> properties;
  final FinancePeriod period;

  const _FinanceBody({required this.properties, required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPaymentsAsync = ref.watch(_allPropertiesPaymentsProvider(properties.map((p) => p.propertyId).toList()));
    return allPaymentsAsync.when(
      data: (allPayments) {
        final filtered = _filterPayments(allPayments, period);
        final totalIncome = filtered.fold<double>(0, (s, p) => s + p.amount);
        final totalProperties = properties.length;
        final avgPerProperty = totalProperties > 0 ? totalIncome / totalProperties : 0.0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SummaryHeader(totalIncome: totalIncome, avgPerProperty: avgPerProperty, period: period),
            const SizedBox(height: 20),
            ...properties.map((property) {
              final propertyPayments = filtered.where((p) => p.propertyId == property.propertyId).toList();
              final propertyTotal = propertyPayments.fold<double>(0, (s, p) => s + p.amount);
              return _PropertyFinanceCard(
                property: property,
                payments: propertyPayments,
                propertyTotal: propertyTotal,
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  List<PaymentModel> _filterPayments(List<PaymentModel> payments, FinancePeriod period) {
    final now = DateTime.now();
    switch (period) {
      case FinancePeriod.thisMonth:
        return payments.where((p) => p.paidAt.month == now.month && p.paidAt.year == now.year).toList();
      case FinancePeriod.lastMonth:
        final last = DateTime(now.year, now.month - 1, 1);
        return payments.where((p) => p.paidAt.month == last.month && p.paidAt.year == last.year).toList();
      case FinancePeriod.thisQuarter:
        final qStart = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
        return payments.where((p) => p.paidAt.isAfter(qStart.subtract(const Duration(days: 1)))).toList();
      case FinancePeriod.thisYear:
        return payments.where((p) => p.paidAt.year == now.year).toList();
      case FinancePeriod.allTime:
        return payments;
    }
  }
}

class _SummaryHeader extends StatelessWidget {
  final double totalIncome;
  final double avgPerProperty;
  final FinancePeriod period;

  const _SummaryHeader({required this.totalIncome, required this.avgPerProperty, required this.period});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(period.label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(Helpers.formatCurrency(totalIncome), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text('Avg ${Helpers.formatCurrency(avgPerProperty)} / property', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _PropertyFinanceCard extends StatelessWidget {
  final PropertyModel property;
  final List<PaymentModel> payments;
  final double propertyTotal;

  const _PropertyFinanceCard({required this.property, required this.payments, required this.propertyTotal});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(property.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Text(Helpers.formatCurrency(propertyTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.success)),
              ],
            ),
            const SizedBox(height: 4),
            Text('${property.totalUnits} units · ${property.availableUnits} available', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            if (payments.isNotEmpty) ...[
              const Divider(height: 24),
              const Text('Payments', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...payments.take(5).map((p) => PaymentCard(payment: p)),
              if (payments.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('+${payments.length - 5} more', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

final _ownerPropertiesProvider = StreamProvider<List<PropertyModel>>((ref) {
  final uid = ref.watch(currentUserProvider).value?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(propertyRepositoryProvider).getPropertiesByOwner(uid);
});

final _allPropertiesPaymentsProvider = FutureProvider.family<List<PaymentModel>, List<String>>((ref, propertyIds) async {
  List<PaymentModel> all = [];
  for (final id in propertyIds) {
    final payments = await ref.read(paymentRepositoryProvider).getPaymentsByProperty(id).first;
    all.addAll(payments);
  }
  all.sort((a, b) => b.paidAt.compareTo(a.paidAt));
  return all;
});
