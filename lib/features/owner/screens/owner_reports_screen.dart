import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/maintenance_repository.dart';
import '../../subscriptions/providers/subscription_provider.dart';
import '../../../widgets/ad_banner.dart';


class OwnerReportsScreen extends ConsumerWidget {
  const OwnerReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Available Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _ReportCard(
            icon: Icons.analytics_outlined,
            title: 'Occupancy Report',
            subtitle: 'View occupancy rates across properties',
            isPremium: false,
            onTap: () => _generateOccupancyReport(context, ref),
          ),
          _ReportCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Financial Summary',
            subtitle: 'Income, expenses, and projections',
            isPremium: true,
            onTap: () => _generateFinancialReport(context, ref),
          ),
          _ReportCard(
            icon: Icons.assessment_outlined,
            title: 'Monthly Statement',
            subtitle: 'Download detailed monthly statement',
            isPremium: true,
            onTap: () => _generateMonthlyStatement(context, ref),
          ),
          _ReportCard(
            icon: Icons.build_outlined,
            title: 'Maintenance Report',
            subtitle: 'Maintenance requests and frequency',
            isPremium: true,
            onTap: () => _generateMaintenanceReport(context, ref),
          ),
          const SizedBox(height: 16),
          const AdBanner(),
        ],
      ),
    );
  }

  Future<void> _generateFinancialReport(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final isPremium = await _checkPremium(ref);
    if (!isPremium) return;

    final properties = await ref.read(propertyRepositoryProvider)
        .getPropertiesByOwner(user.uid).first;
    final from = DateTime.now().subtract(const Duration(days: 30));
    final to = DateTime.now();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Financial Summary Report')),
          pw.SizedBox(height: 20),
          pw.Text('Period: ${Helpers.formatDate(from)} - ${Helpers.formatDate(to)}'),
          pw.SizedBox(height: 20),
          ...properties.map((property) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 1, child: pw.Text(property.name)),
              pw.Text('Units: ${property.totalUnits} | Available: ${property.availableUnits}'),
              pw.SizedBox(height: 8),
            ],
          )),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  Future<void> _generateOccupancyReport(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final properties = await ref.read(propertyRepositoryProvider)
        .getPropertiesByOwner(user.uid).first;

    final propertyUnits = <String, List<int>>{};
    for (final property in properties) {
      final units = await ref.read(propertyRepositoryProvider)
          .getUnitsByProperty(property.propertyId).first;
      final occupied = units.where((u) => u.occupied).length;
      propertyUnits[property.propertyId] = [units.length, occupied];
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Occupancy Report')),
          pw.SizedBox(height: 10),
          pw.Text('Generated: ${Helpers.formatDateTime(DateTime.now())}'),
          pw.SizedBox(height: 20),
          ...properties.map((property) {
            final counts = propertyUnits[property.propertyId] ?? const [0, 0];
            final total = counts[0];
            final occupied = counts[1];
            final rate = total == 0 ? 0 : (occupied / total * 100).toStringAsFixed(1);
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(level: 1, child: pw.Text(property.name)),
                pw.Text('Total Units: $total'),
                pw.Text('Occupied: $occupied'),
                pw.Text('Vacant: ${total - occupied}'),
                pw.Text('Occupancy Rate: $rate%'),
                pw.SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  Future<void> _generateMaintenanceReport(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final isPremium = await _checkPremium(ref);
    if (!isPremium) return;

    final properties = await ref.read(propertyRepositoryProvider)
        .getPropertiesByOwner(user.uid).first;

    final propertyStats = <String, Map<String, int>>{};
    for (final property in properties) {
      propertyStats[property.propertyId] = await _maintenanceStats(ref, property.propertyId);
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Maintenance Report')),
          pw.SizedBox(height: 10),
          pw.Text('Generated: ${Helpers.formatDateTime(DateTime.now())}'),
          pw.SizedBox(height: 20),
          ...properties.map((property) {
            final stats = propertyStats[property.propertyId] ?? const {'total': 0, 'open': 0, 'in_progress': 0, 'resolved': 0};
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(level: 1, child: pw.Text(property.name)),
                pw.Text('Total Requests: ${stats['total']}'),
                pw.Text('Open: ${stats['open']}'),
                pw.Text('In Progress: ${stats['in_progress']}'),
                pw.Text('Resolved: ${stats['resolved']}'),
                pw.SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  Future<Map<String, int>> _maintenanceStats(WidgetRef ref, String propertyId) async {
    final tickets = await ref.read(maintenanceRepositoryProvider)
        .getTicketsByProperty(propertyId).first;
    return {
      'total': tickets.length,
      'open': tickets.where((t) => t.status == 'open').length,
      'in_progress': tickets.where((t) => t.status == 'in_progress').length,
      'resolved': tickets.where((t) => t.status == 'resolved').length,
    };
  }

  Future<void> _generateMonthlyStatement(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final isPremium = await _checkPremium(ref);
    if (!isPremium) return;

    final properties = await ref.read(propertyRepositoryProvider)
        .getPropertiesByOwner(user.uid).first;
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = now;

    final propertyPayments = <String, List<PaymentModel>>{};
    for (final property in properties) {
      final payments = await ref.read(paymentRepositoryProvider)
          .getPaymentsByProperty(property.propertyId).first;
      propertyPayments[property.propertyId] = payments;
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Monthly Statement')),
          pw.SizedBox(height: 10),
          pw.Text('Period: ${Helpers.formatDate(from)} - ${Helpers.formatDate(to)}'),
          pw.SizedBox(height: 20),
          ...properties.map((property) {
            final payments = propertyPayments[property.propertyId] ?? [];
            final total = payments.fold<double>(0.0, (s, p) => s + p.amount);
            if (payments.isEmpty) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Header(level: 1, child: pw.Text(property.name)),
                  pw.Text('No payments this month'),
                  pw.SizedBox(height: 16),
                ],
              );
            }
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(level: 1, child: pw.Text(property.name)),
                pw.Text('Total Collected: KES ${total.toStringAsFixed(2)}'),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  headers: ['Date', 'Amount', 'Method', 'Ref'],
                  data: payments.map((p) => [
                    Helpers.formatDate(p.paidAt),
                    'KES ${p.amount.toStringAsFixed(2)}',
                    p.method.toUpperCase(),
                    p.reference.isNotEmpty ? p.reference : '-',
                  ]).toList(),
                ),
                pw.SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  Future<bool> _checkPremium(WidgetRef ref) async {
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      return false;
    }
    return true;
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPremium;
  final VoidCallback onTap;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isPremium = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withAlpha(25),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Row(
          children: [
            Text(title),
            if (isPremium) ...[
              const SizedBox(width: 8),
              const Icon(Icons.workspace_premium, size: 16, color: Color(0xFFFFA000)),
            ],
          ],
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
