import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/payment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../services/payment_service.dart';

class PayRentScreen extends StatefulWidget {
  final int leaseId;
  final int tenantId;
  final double rentAmount;
  final String tenantName;
  final String unitNumber;

  const PayRentScreen({
    super.key,
    required this.leaseId,
    required this.tenantId,
    required this.rentAmount,
    required this.tenantName,
    required this.unitNumber,
  });

  @override
  State<PayRentScreen> createState() => _PayRentScreenState();
}

class _PayRentScreenState extends State<PayRentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _paymentService = PaymentService.instance;
  String _paymentMethod = 'M-Pesa';
  bool _isProcessing = false;
  String? _statusMessage;
  bool _success = false;

  final _currencyFmt = NumberFormat.currency(symbol: 'KES ', decimalDigits: 2);
  final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.rentAmount.toStringAsFixed(2);
    final auth = context.read<AuthProvider>();
    if (auth.user?.phone.isNotEmpty == true) {
      _phoneController.text = auth.user!.phone;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = null;
      _success = false;
    });

    try {
      final amount = double.parse(_amountController.text);
      final periodStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
      final periodEnd = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

      Map<String, dynamic> result;

      if (_paymentMethod == 'M-Pesa') {
        result = await _paymentService.initiateMpesaPayment(
          phoneNumber: _phoneController.text,
          amount: amount,
          accountReference: 'REMS-${widget.leaseId}',
          transactionDesc: 'Rent ${_dateFmt.format(periodStart)}',
        );

        if (!result['success']) {
          setState(() {
            _statusMessage = result['error'] ?? 'Payment failed';
            _isProcessing = false;
          });
          return;
        }

        // Save pending payment
        final payment = Payment(
          leaseId: widget.leaseId,
          tenantId: widget.tenantId,
          amount: amount,
          paymentDate: DateTime.now(),
          paymentType: 'Rent',
          status: 'Pending',
          paymentMethod: 'M-Pesa',
          transactionId: result['transactionId'] as String?,
          paidBy: 'tenant',
          periodStart: periodStart,
          periodEnd: periodEnd,
          notes: _notesController.text,
        );

        await context.read<PaymentProvider>().addPayment(payment);

        setState(() {
          _success = true;
          _statusMessage =
              'M-Pesa request sent! Check your phone and enter PIN to complete.';
          _isProcessing = false;
        });
      } else {
        // Simulate Cash/Bank payment as pending
        result = await _paymentService.simulatePayment(
          amount: amount,
          method: _paymentMethod,
        );

        final payment = Payment(
          leaseId: widget.leaseId,
          tenantId: widget.tenantId,
          amount: amount,
          paymentDate: DateTime.now(),
          paymentType: 'Rent',
          status: _paymentMethod == 'Cash' ? 'Paid' : 'Pending',
          paymentMethod: _paymentMethod,
          transactionId: result['transactionId'] as String?,
          paidBy: 'tenant',
          periodStart: periodStart,
          periodEnd: periodEnd,
          notes: _notesController.text,
        );

        await context.read<PaymentProvider>().addPayment(payment);

        setState(() {
          _success = true;
          _statusMessage = result['message'] as String? ?? 'Payment recorded';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final periodStart = DateTime(now.year, now.month, 1);
    final periodEnd = DateTime(now.year, now.month + 1, 0);
    final dueDate = DateTime(now.year, now.month, 5); // 5th of month
    final isLate = now.isAfter(dueDate);

    return Scaffold(
      appBar: AppBar(title: const Text('Pay Rent')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Tenant + Unit info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        widget.tenantName.isNotEmpty
                            ? widget.tenantName[0].toUpperCase()
                            : 'T',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.tenantName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Unit ${widget.unitNumber}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Period + Due date
            Row(
              children: [
                Expanded(
                  child: _infoChip(Icons.calendar_today,
                      '${_dateFmt.format(periodStart)} - ${_dateFmt.format(periodEnd)}'),
                ),
                const SizedBox(width: 8),
                _infoChip(
                  isLate ? Icons.warning_amber : Icons.check_circle,
                  'Due: ${_dateFmt.format(dueDate)}',
                  color: isLate ? Colors.orange : Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (KES)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
                prefixText: 'KES ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter amount';
                final amt = double.tryParse(v);
                if (amt == null || amt <= 0) return 'Invalid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Payment Method
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'M-Pesa', child: Text('M-Pesa (STK Push)')),
                DropdownMenuItem(value: 'Card', child: Text('Card Payment')),
                DropdownMenuItem(
                    value: 'Bank Transfer', child: Text('Bank Transfer')),
                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _paymentMethod = v);
              },
            ),
            const SizedBox(height: 16),

            // Phone (only for M-Pesa)
            if (_paymentMethod == 'M-Pesa')
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'M-Pesa Phone Number',
                  hintText: '0712 345 678',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_android),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (_paymentMethod == 'M-Pesa' &&
                      (v == null || v.length < 10)) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Status message
            if (_statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _success
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _success ? Colors.green : Colors.orange,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _success ? Icons.check_circle : Icons.info_outline,
                      color: _success ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_statusMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: _success ? Colors.green[800] : Colors.orange[800],
                          )),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _isProcessing ? null : _submitPayment,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(_paymentMethod == 'M-Pesa'
                        ? Icons.phone_android
                        : Icons.payment),
                label: Text(
                  _isProcessing
                      ? 'Processing...'
                      : _success
                          ? 'Paid'
                          : 'Pay ${_currencyFmt.format(double.tryParse(_amountController.text) ?? 0)}',
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (_success)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.blue[700]),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(fontSize: 11, color: color ?? Colors.blue[700])),
        ],
      ),
    );
  }
}
