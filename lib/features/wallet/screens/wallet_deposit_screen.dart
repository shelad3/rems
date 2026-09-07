import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/mpesa_request_model.dart';
import '../../../data/repositories/mpesa_request_repository.dart';
import '../../../data/services/mpesa_service.dart';
import '../providers/wallet_provider.dart';

class WalletDepositScreen extends ConsumerStatefulWidget {
  final String uid;
  final double amount;

  const WalletDepositScreen({
    super.key,
    required this.uid,
    required this.amount,
  });

  @override
  ConsumerState<WalletDepositScreen> createState() => _WalletDepositScreenState();
}

class _WalletDepositScreenState extends ConsumerState<WalletDepositScreen> {
  final _phoneCtrl = TextEditingController();
  final _mpesaService = MpesaService();
  bool _loading = false;
  String? _statusMessage;
  bool _success = false;
  String? _receipt;
  StreamSubscription<MpesaRequestModel?>? _requestSub;
  Timer? _confirmTimeout;
  bool _settled = false;

  @override
  void dispose() {
    _requestSub?.cancel();
    _confirmTimeout?.cancel();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _deposit() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      Helpers.showSnackBar(context, 'Enter M-Pesa phone number', isError: true);
      return;
    }

    setState(() {
      _loading = true;
      _statusMessage = null;
    });

    try {
      final checkoutId = await _mpesaService.stkPush(
        amount: widget.amount,
        phone: phone,
        accountReference: 'WALLET-${widget.uid.substring(0, 6)}',
        transactionDesc: 'Wallet Deposit',
      );

      await ref.read(mpesaRequestRepositoryProvider).createRequest(
            MpesaRequestModel(
              checkoutRequestId: checkoutId,
              tenantUid: widget.uid,
              propertyId: 'wallet',
              amount: widget.amount,
              intent: 'wallet_deposit',
            ),
          );

      setState(() {
        _statusMessage = 'STK Push sent. Check your phone and enter M-Pesa PIN.';
      });

      _listenForServerConfirm(checkoutId);
      await _confirmFromServer(checkoutId, phone);
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _loading = false;
      });
    }
  }

  void _listenForServerConfirm(String checkoutId) {
    _requestSub?.cancel();
    _confirmTimeout?.cancel();
    _confirmTimeout = Timer(const Duration(seconds: 75), () {
      if (!_settled && mounted) {
        setState(() {
          _statusMessage = 'Deposit still unconfirmed. Check your statement and retry.';
          _loading = false;
        });
      }
    });
    _requestSub = ref
        .read(mpesaRequestRepositoryProvider)
        .streamRequest(checkoutId)
        .listen((request) {
      if (_settled || !mounted) return;
      if (request != null && request.status == 'completed') {
        _settled = true;
        _confirmTimeout?.cancel();
        ref.invalidate(currentWalletProvider);
        setState(() {
          _success = true;
          _receipt = request.receipt;
          _statusMessage = 'Deposit successful! Receipt: ${request.receipt}';
          _loading = false;
        });
      } else if (request != null &&
          (request.status == 'failed' || request.status == 'mismatch')) {
        _settled = true;
        _confirmTimeout?.cancel();
        setState(() {
          _statusMessage = request.status == 'mismatch'
              ? 'Payment amount mismatch detected. Contact support.'
              : 'Payment failed. Please try again.';
          _loading = false;
        });
      }
    });
  }

  Future<void> _confirmFromServer(String checkoutId, String phone) async {
    try {
      final response = await http.post(
        Uri.parse(_mpesaService.callbackUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'checkoutId': checkoutId,
          'phone': phone,
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 &&
          body['ok'] == true &&
          body['status'] == 'completed') {
        _settled = true;
        _confirmTimeout?.cancel();
        ref.invalidate(currentWalletProvider);
        setState(() {
          _success = true;
          _receipt = body['receipt'];
          _statusMessage = 'Deposit successful! Receipt: ${body['receipt']}';
          _loading = false;
        });
      } else if (body['status'] == 'mismatch') {
        setState(() {
          _statusMessage = 'Payment amount mismatch detected. Contact support.';
          _loading = false;
        });
      } else if (body['status'] == 'not_paid') {
        setState(() {
          _statusMessage = 'Payment not yet confirmed on M-Pesa. Try again.';
          _loading = false;
        });
      } else {
        setState(() {
          _statusMessage =
              'Deposit confirmation failed: ${body['reason'] ?? 'Unknown'}';
          _loading = false;
        });
      }
    } on FormatException {
      setState(() {
        _statusMessage = 'Could not confirm payment. Please retry.';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error confirming payment: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Top up Wallet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        size: 64, color: AppColors.primary),
                    const SizedBox(height: 12),
                    const Text('Deposit Amount',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      Helpers.formatCurrency(widget.amount),
                      style: const TextStyle(
                          fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Topped up via M-Pesa STK Push after your payment is confirmed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('M-Pesa Phone Number',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '0712345678',
                prefixText: '+254 ',
                border: OutlineInputBorder(),
              ),
              enabled: !_loading && !_success,
            ),
            const SizedBox(height: 8),
            const Text('Enter the M-Pesa registered phone number',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 24),
            if (_statusMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _success
                      ? AppColors.success.withAlpha(20)
                      : AppColors.error.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(_success ? Icons.check_circle : Icons.info,
                        color: _success ? AppColors.success : AppColors.error,
                        size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                            color: _success ? AppColors.success : AppColors.error,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            if (_statusMessage != null) const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: _success
                  ? ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, _receipt),
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success),
                    )
                  : ElevatedButton.icon(
                      onPressed: _loading ? null : _deposit,
                      icon: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.payments),
                      label: Text(
                          _loading ? 'Processing...' : 'Pay with M-Pesa'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}