import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/pdf_export_service.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Financial Reports',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _reportCard(
            context,
            icon: Icons.account_balance,
            title: 'Profit & Loss Statement',
            subtitle: 'Income vs expenses for a given year',
            color: Colors.blue,
            onTap: () => _showYearPicker(context, (year) {
              PdfExportService.instance.exportProfitLoss(year);
            }),
          ),
          const SizedBox(height: 8),
          _reportCard(
            context,
            icon: Icons.trending_up,
            title: 'Cash Flow Statement',
            subtitle: 'Monthly cash flow over the year',
            color: Colors.green,
            onTap: () => _showYearPicker(context, (year) {
              PdfExportService.instance.exportCashFlow(year);
            }),
          ),
          const SizedBox(height: 8),
          _reportCard(
            context,
            icon: Icons.description,
            title: 'Schedule E Report',
            subtitle: 'Supplemental income & loss per property',
            color: Colors.purple,
            onTap: () => _showYearPicker(context, (year) {
              PdfExportService.instance.exportScheduleE(year);
            }),
          ),
          const SizedBox(height: 24),
          Text('Property Reports',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _reportCard(
            context,
            icon: Icons.receipt,
            title: 'Rent Roll',
            subtitle: 'Active leases with tenant, unit, and rent details',
            color: Colors.teal,
            onTap: () => PdfExportService.instance.exportRentRoll(),
          ),
          const SizedBox(height: 8),
          _reportCard(
            context,
            icon: Icons.build,
            title: 'Maintenance Report',
            subtitle: 'All maintenance requests summary',
            color: Colors.orange,
            onTap: () => PdfExportService.instance.exportMaintenanceReport(),
          ),
          const SizedBox(height: 24),
          Text('Export & Integration',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _reportCard(
            context,
            icon: Icons.table_chart,
            title: 'QuickBooks CSV',
            subtitle: 'Export payments as CSV for QuickBooks import',
            color: Colors.indigo,
            onTap: () => _showYearPicker(context, (year) {
              PdfExportService.instance.exportQuickBooksCSV(year);
            }),
          ),
          const SizedBox(height: 24),
          Text(
            'PDF reports will be generated and shared via the share sheet.',
            style: TextStyle(
                fontSize: 12, color: Theme.of(context).colorScheme.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _reportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showYearPicker(BuildContext context, void Function(int year) onSelect) {
    final now = DateTime.now();
    final years = List.generate(5, (i) => now.year - 2 + i);
    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Select Year',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            ...years.map((y) => ListTile(
                  title: Text(y.toString()),
                  trailing: y == now.year
                      ? const Icon(Icons.check, size: 18)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    onSelect(y);
                  },
                )),
          ],
        ),
      ),
    );
  }
}
