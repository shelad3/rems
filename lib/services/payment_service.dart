import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  static final PaymentService instance = PaymentService._init();
  PaymentService._init();

  // M-Pesa Daraja API (Safaricom Kenya)
  // Credentials from https://developer.safaricom.co.ke
  static const String _mpesaConsumerKey = '311q56YJCLOyHfiAGvcWwCGPcq7qyKcm7KAX2612CC1LLyjG';
  static const String _mpesaConsumerSecret = '22FYoa5DjnQ9k6gE1jMkBR3Rhz5n4CF5JwUKAjdzQsfpVq6eAAf9VCpQqwmljO5g';
  static const String _mpesaPasskey = 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919';
  static const String _mpesaShortCode = '174379';
  static const String _mpesaCallbackUrl =
      'https://us-central1-rems-dae41.cloudfunctions.net/mpesaCallback';

  // Generate a unique transaction ID
  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(99999);
    return 'REMS$timestamp$random';
  }

  // ===================== M-PESA STK PUSH =====================

  Future<String?> _getMpesaAccessToken() async {
    try {
      final credentials =
          base64Encode(utf8.encode('$_mpesaConsumerKey:$_mpesaConsumerSecret'));
      final response = await http.post(
        Uri.parse(
            'https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials'),
        headers: {'Authorization': 'Basic $credentials'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'] as String?;
      }
    } catch (e) {
      debugPrint('M-Pesa token error: $e');
    }
    return null;
  }

  static String _timestamp() {
    final now = DateTime.now();
    return '${now.year}${_pad(now.month)}${_pad(now.day)}'
        '${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  String _generatePassword() {
    final raw = '$_mpesaShortCode$_mpesaPasskey${_timestamp()}';
    return base64Encode(utf8.encode(raw));
  }

  Future<Map<String, dynamic>> initiateMpesaPayment({
    required String phoneNumber,
    required double amount,
    required String accountReference,
    required String transactionDesc,
  }) async {
    final token = await _getMpesaAccessToken();
    if (token == null) {
      return {
        'success': false,
        'error': 'Failed to get M-Pesa access token. Check your credentials.',
      };
    }

    try {
      // Format phone: 2547XXXXXXXX
      String formattedPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '254${formattedPhone.substring(1)}';
      } else if (formattedPhone.startsWith('+')) {
        formattedPhone = formattedPhone.substring(1);
      }
      if (!formattedPhone.startsWith('254')) {
        formattedPhone = '254$formattedPhone';
      }

      final amountInt = (amount * 100).round(); // Amount in cents (KES)
      final transactionId = _generateTransactionId();

      final response = await http.post(
        Uri.parse(
            'https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'BusinessShortCode': _mpesaShortCode,
          'Password': _generatePassword(),
          'Timestamp': _timestamp(),
          'TransactionType': 'CustomerPayBillOnline',
          'Amount': amountInt,
          'PartyA': formattedPhone,
          'PartyB': _mpesaShortCode,
          'PhoneNumber': formattedPhone,
          'CallBackURL': _mpesaCallbackUrl,
          'AccountReference':
              accountReference.length > 12 ? accountReference.substring(0, 12) : accountReference,
          'TransactionDesc':
              transactionDesc.length > 13 ? transactionDesc.substring(0, 13) : transactionDesc,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final success = data['ResponseCode'] == '0';
        return {
          'success': success,
          'transactionId': transactionId,
          'merchantRequestId': data['MerchantRequestID'],
          'checkoutRequestId': data['CheckoutRequestID'],
          'responseDescription': data['ResponseDescription'],
          'error': success ? null : data['ResponseDescription'],
        };
      } else {
        return {
          'success': false,
          'error': 'M-Pesa API error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('M-Pesa STK push error: $e');
      return {
        'success': false,
        'error': 'Payment request failed. Check your connection.',
      };
    }
  }

  // Query M-Pesa payment status
  Future<Map<String, dynamic>> queryMpesaStatus(String checkoutRequestId) async {
    final token = await _getMpesaAccessToken();
    if (token == null) {
      return {'success': false, 'error': 'Auth failed'};
    }

    try {
      final response = await http.post(
        Uri.parse(
            'https://sandbox.safaricom.co.ke/mpesa/stkpushquery/v1/query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'BusinessShortCode': _mpesaShortCode,
          'Password': _generatePassword(),
          'Timestamp': _timestamp(),
          'CheckoutRequestID': checkoutRequestId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['ResultCode'] == '0',
          'resultCode': data['ResultCode'],
          'resultDesc': data['ResultDesc'],
          'mpesaReceipt': data['MpesaReceiptNumber'],
          'phoneNumber': data['PhoneNumber'],
          'amount': data['Amount'],
        };
      }
    } catch (e) {
      debugPrint('M-Pesa query error: $e');
    }
    return {'success': false, 'error': 'Query failed'};
  }

  // ===================== CARD PAYMENT (Stripe) =====================

  // For Stripe, we use Firebase Functions to create PaymentIntents
  // The Flutter client calls a callable function which returns a client_secret
  Future<Map<String, dynamic>> createStripePaymentIntent({
    required double amount,
    required String currency,
    required String description,
  }) async {
    // In production, call a Firebase Callable Function:
    // final result = await FirebaseFunctions.instance
    //     .httpsCallable('createPaymentIntent')
    //     .call({'amount': (amount * 100).round(), 'currency': currency});
    // return result.data as Map<String, dynamic>;

    return {
      'success': false,
      'error': 'Stripe integration: create a callable function first',
    };
  }

  // ===================== SIMULATED PAYMENT (for testing) =====================

  Future<Map<String, dynamic>> simulatePayment({
    required double amount,
    required String method,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    final transactionId = _generateTransactionId();
    return {
      'success': true,
      'transactionId': transactionId,
      'receipt': method == 'M-Pesa' ? 'MPE${transactionId.substring(0, 10)}' : null,
      'message': 'Payment of KES ${amount.toStringAsFixed(2)} successful',
    };
  }
}
