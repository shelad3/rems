import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'firestore_service.dart';

class PdfExportService {
  static final PdfExportService instance = PdfExportService._();
  PdfExportService._();
  final _firestore = FirestoreService.instance;

  Future<void> exportRentRoll() async {
    final leasesSnapshot = await _firestore.db.collection('leases').get();
    final leases = leasesSnapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    }).toList();
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Header(
          level: 0,
          child: pw.Text('Rent Roll Report',
              style: pw.TextStyle(
                  fontSize: 22, fontWeight: pw.FontWeight.bold)),
        ),
        footer: (context) => pw.Text(
          'Generated ${dateFormat.format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
        ),
        build: (context) => [
          pw.Paragraph(
              text:
                  'Active Leases: ${leases.length} | Generated: ${dateFormat.format(DateTime.now())}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Tenant', 'Property', 'Unit', 'Rent', 'Period', 'Status'],
            data: leases.map((l) {
              final start = dateFormat
                  .format(DateTime.parse(l['start_date'] as String));
              final end = dateFormat
                  .format(DateTime.parse(l['end_date'] as String));
              final isExpired =
                  DateTime.parse(l['end_date'] as String).isBefore(DateTime.now());
              return [
                l['tenant_name'] as String? ?? 'Unknown',
                l['property_name'] as String? ?? 'Unknown',
                'Unit ${l['unit_number'] as String? ?? '?'}',
                currencyFormat.format((l['rent_amount'] as num?)?.toDouble() ?? 0),
                '$start - $end',
                isExpired ? 'Expired' : 'Active',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellStyle: const pw.TextStyle(fontSize: 9),
            rowDecoration: pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300)),
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Summary',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.SizedBox(height: 4),
                pw.Text(
                    'Total Active Leases: ${leases.where((l) => DateTime.parse(l['end_date'] as String).isAfter(DateTime.now())).length}'),
                pw.Text('Total Monthly Rent: ${currencyFormat.format(
                  leases.fold<double>(0, (sum, l) =>
                      sum + ((l['rent_amount'] as num?)?.toDouble() ?? 0)),
                )}'),
              ],
            ),
          ),
        ],
      ),
    );

    await _saveAndShare(pdf, 'rent_roll_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
  }

  Future<void> exportPropertyReport(String propertyId) async {
    final propDoc = await _firestore.db.collection('properties').doc(propertyId).get();
    if (!propDoc.exists) return;
    final property = {'id': propDoc.id, ...propDoc.data() as Map<String, dynamic>};
    final unitsSnapshot = await _firestore.db.collection('units')
        .where('propertyId', isEqualTo: propertyId).get();
    final units = unitsSnapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    }).toList();
    final maintenanceSnapshot = await _firestore.db.collection('maintenance_requests')
        .where('propertyId', isEqualTo: propertyId).get();
    final maintenance = maintenanceSnapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    }).toList();
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Header(
          level: 0,
          child: pw.Text(property['name'] as String? ?? 'Property Report'),
        ),
        build: (context) => [
          pw.Paragraph(
              text:
                  'Address: ${property['address']}, ${property['city']}, ${property['state']} ${property['zip']}'),
          pw.Paragraph(
              text: 'Owner: ${property['owner_name'] ?? 'Unknown'}'),
          pw.SizedBox(height: 16),
          pw.Header(level: 1, text: 'Units (${units.length})'),
          pw.TableHelper.fromTextArray(
            headers: ['Unit', 'BR/BA', 'Rent', 'Status'],
            data: units.map((u) => [
              u['unit_number'] as String? ?? '',
              '${u['bedrooms']}/${u['bathrooms']}',
              currencyFormat
                  .format((u['rent_amount'] as num?)?.toDouble() ?? 0),
              (u['is_occupied'] as int?) == 1 ? 'Occupied' : 'Vacant',
            ]).toList(),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blue800),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 24),
          pw.Header(level: 1, text: 'Maintenance Requests'),
          maintenance.isEmpty
              ? pw.Paragraph(text: 'No maintenance requests')
              : pw.TableHelper.fromTextArray(
                  headers: ['Title', 'Priority', 'Status', 'Date'],
                  data: maintenance.map((m) => [
                    m['title'] as String? ?? '',
                    m['priority'] as String? ?? '',
                    m['status'] as String? ?? '',
                    dateFormat
                        .format(DateTime.parse(m['created_at'] as String)),
                  ]).toList(),
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.blue800),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                ),
        ],
      ),
    );

    await _saveAndShare(pdf,
        'property_${property['name']}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
  }

  Future<void> exportProfitLoss(int year) async {
    final expensesSnapshot = await _firestore.db.collection('expenses').get();
    final expenses = expensesSnapshot.docs.map((doc) => ({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    })).toList();
    final paymentsSnapshot = await _firestore.db.collection('payments').get();
    final allPayments = paymentsSnapshot.docs.map((doc) => ({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    })).toList();
    final revenue = <Map<String, dynamic>>[];
    for (int m = 1; m <= 12; m++) {
      final total = allPayments
          .where((p) {
            try {
              final date = DateTime.parse(p['paymentDate'] as String);
              return date.month == m && date.year == year && p['status'] == 'Paid';
            } catch (_) {
              return false;
            }
          })
          .fold<double>(0, (s, r) => s + ((r['amount'] as num?)?.toDouble() ?? 0));
      if (total > 0) {
        revenue.add({'month': m, 'total': total});
      }
    }
    final currencyFormat = NumberFormat.currency(symbol: 'KSH ');
    final dateFormat = DateFormat('MMM dd, yyyy');

    final totalRevenue =
        revenue.fold<double>(0, (s, r) => s + ((r['total'] as num?)?.toDouble() ?? 0));
    final totalExpenses =
        expenses.fold<double>(0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0));

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Header(
          level: 0,
          child: pw.Text('Profit & Loss Statement $year',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        ),
        footer: (context) => pw.Text(
          'Generated ${dateFormat.format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
        ),
        build: (context) => [
          pw.Header(level: 1, text: 'Income'),
          revenue.isEmpty
              ? pw.Paragraph(text: 'No income recorded')
              : pw.TableHelper.fromTextArray(
                  headers: ['Month', 'Amount'],
                  data: revenue.map((r) => [
                    DateFormat('MMMM').format(DateTime(year, r['month'] as int)),
                    currencyFormat.format((r['total'] as num?)?.toDouble() ?? 0),
                  ]).toList(),
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.green800),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: const pw.BoxDecoration(color: PdfColors.green50),
            child: pw.Text('Total Income: ${currencyFormat.format(totalRevenue)}',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
          ),
          pw.SizedBox(height: 24),
          pw.Header(level: 1, text: 'Expenses'),
          expenses.isEmpty
              ? pw.Paragraph(text: 'No expenses recorded')
              : pw.TableHelper.fromTextArray(
                  headers: ['Title', 'Category', 'Amount', 'Date'],
                  data: expenses.map((e) => [
                    e['title'] as String? ?? '',
                    e['category'] as String? ?? '',
                    currencyFormat.format((e['amount'] as num?)?.toDouble() ?? 0),
                    dateFormat.format(DateTime.parse(e['expense_date'] as String)),
                  ]).toList(),
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.red800),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: const pw.BoxDecoration(color: PdfColors.red50),
            child: pw.Text('Total Expenses: ${currencyFormat.format(totalExpenses)}',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
          ),
          pw.Divider(),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'Net Profit/Loss: ${currencyFormat.format(totalRevenue - totalExpenses)}',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                  color: totalRevenue >= totalExpenses
                      ? PdfColors.green800
                      : PdfColors.red800),
            ),
          ),
        ],
      ),
    );

    await _saveAndShare(pdf,
        'pnl_$year.pdf');
  }

  Future<void> exportCashFlow(int year) async {
    final expensesSnapshot = await _firestore.db.collection('expenses').get();
    final expenses = expensesSnapshot.docs.map((doc) => ({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    })).toList();
    final paymentsSnapshot = await _firestore.db.collection('payments').get();
    final allPayments = paymentsSnapshot.docs.map((doc) => ({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    })).toList();
    final revenue = <Map<String, dynamic>>[];
    for (int m = 1; m <= 12; m++) {
      final total = allPayments
          .where((p) {
            try {
              final date = DateTime.parse(p['paymentDate'] as String);
              return date.month == m && date.year == year && p['status'] == 'Paid';
            } catch (_) {
              return false;
            }
          })
          .fold<double>(0, (s, r) => s + ((r['amount'] as num?)?.toDouble() ?? 0));
      if (total > 0) {
        revenue.add({'month': m, 'total': total});
      }
    }
    final currencyFormat = NumberFormat.currency(symbol: 'KSH ');
    final dateFormat = DateFormat('MMM yyyy');

    final monthlyCashFlow = <Map<String, dynamic>>[];
    for (int m = 1; m <= 12; m++) {
      final rev = revenue.where((r) => r['month'] == m).fold<double>(
          0, (s, r) => s + ((r['total'] as num?)?.toDouble() ?? 0));
      final exp = expenses
          .where((e) {
            try {
              return DateTime.parse(e['expense_date'] as String).month == m &&
                  DateTime.parse(e['expense_date'] as String).year == year;
            } catch (_) {
              return false;
            }
          })
          .fold<double>(
              0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0));
      monthlyCashFlow.add({
        'month': DateFormat('MMMM').format(DateTime(year, m)),
        'revenue': rev,
        'expenses': exp,
        'net': rev - exp,
      });
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Header(
          level: 0,
          child: pw.Text('Cash Flow Statement $year',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: ['Month', 'Revenue', 'Expenses', 'Net Cash Flow'],
            data: monthlyCashFlow.map((m) => [
              m['month'],
              currencyFormat.format(m['revenue']),
              currencyFormat.format(m['expenses']),
              currencyFormat.format(m['net']),
            ]).toList(),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blue800),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Annual Summary',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.SizedBox(height: 4),
                pw.Text(
                    'Total Revenue: ${currencyFormat.format(monthlyCashFlow.fold<double>(0, (s, m) => s + (m['revenue'] as double)))}'),
                pw.Text(
                    'Total Expenses: ${currencyFormat.format(monthlyCashFlow.fold<double>(0, (s, m) => s + (m['expenses'] as double)))}'),
                pw.Text(
                    'Net Cash Flow: ${currencyFormat.format(monthlyCashFlow.fold<double>(0, (s, m) => s + (m['net'] as double)))}'),
              ],
            ),
          ),
        ],
      ),
    );

    await _saveAndShare(pdf, 'cash_flow_$year.pdf');
  }

  Future<void> exportScheduleE(int year) async {
    final propertiesSnapshot = await _firestore.db.collection('properties').get();
    final properties = propertiesSnapshot.docs.map((doc) => ({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    })).toList();
    final currencyFormat = NumberFormat.currency(symbol: 'KSH ');
    final dateFormat = DateFormat('MMM dd, yyyy');

    // Pre-fetch all data for each property
    final propertyData = <Map<String, dynamic>>[];
    for (final prop in properties) {
      final pid = prop['id'] as String;
      final rentCollected = await _getPropertyRentCollected(pid, year);
      final totalExpenses = await _getPropertyTotalExpenses(pid, year);
      final expenseCategories = <Map<String, dynamic>>[];
      for (final cat in ['Repairs', 'Maintenance', 'Utilities',
          'Insurance', 'Property Management', 'Cleaning',
          'Supplies', 'Advertising', 'Legal', 'Other']) {
        expenseCategories.add({
          'category': cat,
          'total': await _getPropertyExpenseByCategory(pid, cat, year),
        });
      }
      propertyData.add({
        'name': prop['name'] as String? ?? 'Property',
        'address': prop['address'] as String? ?? '',
        'city': prop['city'] as String? ?? '',
        'state': prop['state'] as String? ?? '',
        'rentCollected': rentCollected,
        'totalExpenses': totalExpenses,
        'expenseCategories': expenseCategories,
      });
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Header(
          level: 0,
          child: pw.Text('Schedule E - Supplemental Income & Loss',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        ),
        build: (context) => [
          pw.Text('For calendar year $year',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          for (final prop in propertyData) ...[
            pw.Header(
              level: 1,
              text: prop['name'] as String,
            ),
            pw.Paragraph(
                text:
                    'Address: ${prop['address']}, ${prop['city']}, ${prop['state']}'),
            pw.SizedBox(height: 8),
            _buildScheduleESection(
              'Rental Income',
              [
                _scheduleERow('Rent Collected', prop['rentCollected'] as double),
                _scheduleERow('Total Rental Income', prop['rentCollected'] as double),
              ],
              currencyFormat,
            ),
            pw.SizedBox(height: 8),
            _buildScheduleESection(
              'Expenses',
              (prop['expenseCategories'] as List<Map<String, dynamic>>).map((ec) =>
                _scheduleERow(ec['category'] as String, ec['total'] as double)
              ).toList(),
              currencyFormat,
            ),
            pw.Divider(),
            _buildScheduleETotal(
              'Net Rental Income/Loss',
              (prop['rentCollected'] as double) - (prop['totalExpenses'] as double),
              currencyFormat,
            ),
            pw.SizedBox(height: 24),
          ],
          pw.Header(level: 1, text: 'Summary'),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Total Properties: ${properties.length}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(
                    'Generated: ${dateFormat.format(DateTime.now())}'),
                pw.Text(
                    'This is a simulated Schedule E for management purposes. '
                    'Consult your tax professional for official filings.',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
              ],
            ),
          ),
        ],
      ),
    );

    await _saveAndShare(pdf, 'schedule_e_$year.pdf');
  }

  pw.Widget _buildScheduleESection(
      String title, List<pw.Widget> rows, NumberFormat fmt) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 11)),
          ...rows,
        ],
      ),
    );
  }

  pw.Widget _scheduleERow(String label, double amount) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        pw.Text(NumberFormat.currency(symbol: 'KSH ').format(amount),
            style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  pw.Widget _buildScheduleETotal(String label, double amount, NumberFormat fmt) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: amount >= 0 ? PdfColors.green50 : PdfColors.red50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
          pw.Text(fmt.format(amount),
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: amount >= 0 ? PdfColors.green800 : PdfColors.red800)),
        ],
      ),
    );
  }

  Future<double> _getPropertyRentCollected(String propertyId, int year) async {
    final snapshot = await _firestore.db.collection('payments').get();
    final payments = snapshot.docs.map((doc) => ({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    })).toList();
    final total = payments
        .where((p) =>
            p['propertyId'] == propertyId &&
            p['status'] == 'Paid' &&
            DateTime.parse(p['paymentDate'] as String).year == year)
        .fold<double>(0, (s, p) => s + ((p['amount'] as num?)?.toDouble() ?? 0));
    return total;
  }

  Future<double> _getPropertyExpenseByCategory(
      String propertyId, String category, int year) async {
    final snapshot = await _firestore.db.collection('expenses').get();
    final expenses = snapshot.docs.map((doc) => ({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    })).toList();
    final total = expenses
        .where((e) =>
            e['propertyId'] == propertyId &&
            e['category'] == category &&
            DateTime.parse(e['expenseDate'] as String).year == year)
        .fold<double>(0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0));
    return total;
  }

  Future<double> _getPropertyTotalExpenses(String propertyId, int year) async {
    final snapshot = await _firestore.db.collection('expenses').get();
    final expenses = snapshot.docs.map((doc) => ({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    })).toList();
    final total = expenses
        .where((e) =>
            e['propertyId'] == propertyId &&
            DateTime.parse(e['expenseDate'] as String).year == year)
        .fold<double>(0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0));
    return total;
  }

  Future<void> exportMaintenanceReport() async {
    final requestsSnapshot = await _firestore.db.collection('maintenance_requests').get();
    final requests = requestsSnapshot.docs.map((doc) => ({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    })).toList();
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Header(
          level: 0,
          child: pw.Text('Maintenance Report'),
        ),
        build: (context) => [
          pw.Paragraph(
              text:
                  'Total Requests: ${requests.length} | Generated: ${dateFormat.format(DateTime.now())}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Title', 'Priority', 'Status', 'Date'],
            data: requests.map((r) => [
              r['title'] as String? ?? '',
              r['priority'] as String? ?? '',
              r['status'] as String? ?? '',
              dateFormat.format(DateTime.parse(r['created_at'] as String)),
            ]).toList(),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blue800),
            cellStyle: const pw.TextStyle(fontSize: 9),
            rowDecoration: pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300)),
            ),
          ),
          pw.SizedBox(height: 24),
          _buildSummaryBox(context, requests),
        ],
      ),
    );

    await _saveAndShare(pdf,
        'maintenance_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
  }

  pw.Widget _buildSummaryBox(
      pw.Context context, List<Map<String, dynamic>> requests) {
    final pending = requests.where((r) => r['status'] == 'Pending').length;
    final inProgress =
        requests.where((r) => r['status'] == 'In Progress').length;
    final completed =
        requests.where((r) => r['status'] == 'Completed').length;
    final emergency =
        requests.where((r) => r['priority'] == 'Emergency').length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Summary',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 4),
          pw.Text('Pending: $pending | In Progress: $inProgress | Completed: $completed'),
          pw.Text('Emergency: $emergency'),
        ],
      ),
    );
  }

  Future<void> exportQuickBooksCSV(int year) async {
    final paymentsSnapshot = await _firestore.db.collection('payments').get();
    final payments = paymentsSnapshot.docs.map((doc) => ({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    })).toList();
    final currencyFormat = NumberFormat.currency(symbol: 'KSH ', decimalDigits: 0);

    final buffer = StringBuffer();
    buffer.writeln('Date,Name,Description,Amount,Type,Status');
    for (final p in payments) {
      final date = p['payment_date'] as String? ?? '';
      final name = 'Tenant #${p['tenant_id']}';
      final desc = p['payment_type'] as String? ?? 'Rent';
      final amount = currencyFormat.format((p['amount'] as num?)?.toDouble() ?? 0);
      final type = p['payment_method'] as String? ?? 'Cash';
      final status = p['status'] as String? ?? 'Paid';
      buffer.writeln('$date,$name,$desc,$amount,$type,$status');
    }

    final bytes = Uint8List.fromList(buffer.toString().codeUnits);
    await _saveAndShareBytes(bytes, 'quickbooks_$year.csv');
  }

  Future<String> _saveToFile(Uint8List bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> _saveAndShareBytes(Uint8List bytes, String filename) async {
    final path = await _saveToFile(bytes, filename);
    await Share.shareXFiles(
      [XFile(path)],
      subject: filename,
    );
  }

  Future<void> _saveAndShare(pw.Document pdf, String filename) async {
    final bytes = await pdf.save();
    final path = await _saveToFile(bytes, filename);
    await Share.shareXFiles(
      [XFile(path)],
      subject: filename,
    );
  }
}
