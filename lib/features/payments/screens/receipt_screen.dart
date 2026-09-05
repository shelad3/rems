import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/models/property_model.dart';
import '../../../data/repositories/property_repository.dart';

class ReceiptScreen extends ConsumerWidget {
  final PaymentModel payment;

  const ReceiptScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyAsync = ref.watch(_propertyProvider(payment.propertyId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _generatePdf(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _generatePdf(context, ref, share: true),
          ),
        ],
      ),
      body: propertyAsync.when(
        data: (property) => _buildReceipt(context, property),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildReceipt(BuildContext context, PropertyModel? property) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle, size: 64, color: AppColors.success),
                const SizedBox(height: 12),
                const Text('Payment Successful', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(Helpers.formatDate(payment.paidAt), style: const TextStyle(color: AppColors.textSecondary)),
                const Divider(height: 32),
                _ReceiptRow(label: 'Receipt No', value: payment.reference),
                _ReceiptRow(label: 'Property', value: property?.name ?? 'N/A'),
                _ReceiptRow(label: 'Amount', value: Helpers.formatCurrency(payment.amount), isBold: true),
                _ReceiptRow(label: 'Method', value: payment.method.toUpperCase()),
                _ReceiptRow(label: 'Status', value: payment.status.toUpperCase()),
                const Divider(height: 24),
                const Text('Thank you for your payment!', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdf(BuildContext context, WidgetRef ref, {bool share = false}) async {
    final property = await ref.read(propertyRepositoryProvider).getPropertyById(payment.propertyId).first;

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('PAYMENT RECEIPT', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('REMS', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey)),
            pw.Divider(),
            pw.SizedBox(height: 8),
            _pdfRow('Receipt:', payment.reference),
            _pdfRow('Property:', property?.name ?? 'N/A'),
            _pdfRow('Amount:', Helpers.formatCurrency(payment.amount)),
            _pdfRow('Method:', payment.method.toUpperCase()),
            _pdfRow('Date:', Helpers.formatDate(payment.paidAt)),
            _pdfRow('Status:', payment.status.toUpperCase()),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text('Thank you for your payment!', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          ],
        ),
      ),
    );

    if (share) {
      await Printing.sharePdf(bytes: await pdf.save(), filename: 'receipt_${payment.reference}.pdf');
    } else {
      await Printing.layoutPdf(onLayout: (_) async => pdf.save());
    }
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey)),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}

final _propertyProvider = StreamProvider.family<PropertyModel?, String>((ref, propertyId) {
  return ref.read(propertyRepositoryProvider).getPropertyById(propertyId);
});

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _ReceiptRow({required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }
}
