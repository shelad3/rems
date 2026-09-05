import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/property_model.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/rent_invoice_repository.dart';
import '../../../data/repositories/maintenance_repository.dart';

class OwnerMetrics {
  final double totalIncome;
  final int totalUnits;
  final double occupancyRate;
  final int openTickets;
  final int propertyCount;
  final double arrears;

  OwnerMetrics({
    required this.totalIncome,
    required this.totalUnits,
    required this.occupancyRate,
    required this.openTickets,
    required this.propertyCount,
    required this.arrears,
  });
}

final ownerPropertiesProvider = StreamProvider<List<PropertyModel>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  return ref.watch(propertyRepositoryProvider).getPropertiesByOwner(user.uid);
});

final ownerAggregatedMetricsProvider = FutureProvider<OwnerMetrics>((ref) async {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final properties = await ref.read(propertyRepositoryProvider).getPropertiesByOwner(userId).first;

  double totalIncome = 0;
  int totalUnits = 0;
  int occupiedUnits = 0;
  int totalTickets = 0;
  double arrears = 0;

  for (final property in properties) {
    totalUnits += property.totalUnits;

    final payments = await ref.read(paymentRepositoryProvider)
        .getPaymentsByProperty(property.propertyId).first;
    totalIncome += payments.fold<double>(0.0, (sum, p) => sum + p.amount);

    final invoices = await ref.read(rentInvoiceRepositoryProvider)
        .getInvoicesByProperty(property.propertyId).first;
    arrears += invoices.where((inv) => !inv.isPaid)
        .fold<double>(0.0, (sum, inv) => sum + inv.outstanding);

    final units = await ref.read(propertyRepositoryProvider)
        .getUnitsByProperty(property.propertyId).first;
    occupiedUnits += units.where((u) => u.occupied).length;

    final tickets = await ref.read(maintenanceRepositoryProvider)
        .getTicketsByProperty(property.propertyId).first;
    totalTickets += tickets.where((t) => t.status != 'resolved').length;
  }

  return OwnerMetrics(
    totalIncome: totalIncome,
    totalUnits: totalUnits,
    occupancyRate: totalUnits > 0 ? (occupiedUnits / totalUnits * 100) : 0,
    openTickets: totalTickets,
    propertyCount: properties.length,
    arrears: arrears,
  );
});

final selectedPropertyProvider = StateProvider<String?>((ref) => null);
