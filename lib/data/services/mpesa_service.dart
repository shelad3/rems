import 'dart:convert';
import 'package:http/http.dart' as http;

class MpesaService {
  // Credentials are injected at build time via --dart-define so real secrets
  // are never bundled into the shipped APK. Sandbox-safe defaults are used
  // when they aren't provided.
  static const String _envConsumerKey = String.fromEnvironment('MPESA_CONSUMER_KEY');
  static const String _envConsumerSecret = String.fromEnvironment('MPESA_CONSUMER_SECRET');
  static const String _envPasskey = String.fromEnvironment('MPESA_PASSKEY');
  static const String _envShortcode = String.fromEnvironment('MPESA_SHORTCODE');
  static const String _envCallbackUrl = String.fromEnvironment('MPESA_CALLBACK_URL');
  static const String _envMpesaEnv = String.fromEnvironment('MPESA_ENV');

  String get _consumerKey => _envConsumerKey;
  String get _consumerSecret => _envConsumerSecret;
  String get _passkey => _envPasskey.isEmpty ? 'sandbox' : _envPasskey;
  String get _shortcode => _envShortcode.isEmpty ? '174379' : _envShortcode;
  String get _callbackUrl => _envCallbackUrl.isEmpty
      ? 'https://your-domain.com/mpesa/callback'
      : _envCallbackUrl;

  String get callbackUrl => _callbackUrl;

  bool get _isProduction => _envMpesaEnv == 'production';
  String get _baseUrl =>
      _isProduction ? 'https://api.safaricom.co.ke' : 'https://sandbox.safaricom.co.ke';
  static const String _authPath = '/oauth/v1/generate?grant_type=client_credentials';
  static const String _stkPushPath = '/mpesa/stkpush/v1/processrequest';
  static const String _stkQueryPath = '/mpesa/stkpushquery/v1/query';

  Future<String> _getAccessToken() async {
    final credentials = base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'));
    final response = await http.get(
      Uri.parse('$_baseUrl$_authPath'),
      headers: {'Authorization': 'Basic $credentials'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    }
    throw Exception('Failed to get M-Pesa access token: ${response.statusCode} ${response.body}');
  }

  String generateTimestamp() {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    return '$year$month$day$hour$minute$second';
  }

  Future<String> _generatePassword() async {
    final timestamp = generateTimestamp();
    final str = '$_shortcode$_passkey$timestamp';
    return base64Encode(utf8.encode(str));
  }

  Future<String> stkPush({
    required double amount,
    required String phone,
    required String accountReference,
    String transactionDesc = 'Rent Payment',
  }) async {
    final token = await _getAccessToken();
    final timestamp = generateTimestamp();
    final password = await _generatePassword();
    final formattedPhone = phone.replaceAll(RegExp(r'\D'), '');
    final msisdn = formattedPhone.startsWith('0')
        ? '254${formattedPhone.substring(1)}'
        : formattedPhone.startsWith('254')
            ? formattedPhone
            : '254$formattedPhone';

    final body = {
      'BusinessShortCode': _shortcode,
      'Password': password,
      'Timestamp': timestamp,
      'TransactionType': 'CustomerPayBillOnline',
      'Amount': amount.round().toString(),
      'PartyA': msisdn,
      'PartyB': _shortcode,
      'PhoneNumber': msisdn,
      'CallBackURL': _callbackUrl,
      'AccountReference': accountReference.length > 12 ? accountReference.substring(0, 12) : accountReference,
      'TransactionDesc': transactionDesc,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl$_stkPushPath'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['ResponseCode'] == '0') {
        return data['CheckoutRequestID'];
      }
      throw Exception('STK Push failed: ${data['ResponseDescription'] ?? 'Unknown error'}');
    }
    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }

  Future<Map<String, dynamic>> queryStatus(String checkoutRequestId) async {
    final token = await _getAccessToken();
    final timestamp = generateTimestamp();
    final password = await _generatePassword();

    final body = {
      'BusinessShortCode': _shortcode,
      'Password': password,
      'Timestamp': timestamp,
      'CheckoutRequestID': checkoutRequestId,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl$_stkQueryPath'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Query failed: ${response.statusCode} ${response.body}');
  }

  Future<Map<String, dynamic>> simulateCallback({
    required double amount,
    required String phone,
    required String accountReference,
    required String checkoutRequestId,
    bool success = true,
  }) async {
    return {
      'Body': {
        'stkCallback': {
          'MerchantRequestID': '${DateTime.now().millisecondsSinceEpoch}',
          'CheckoutRequestID': checkoutRequestId,
          'ResultCode': success ? 0 : 1,
          'ResultDesc': success ? 'The service request is processed successfully.' : 'The payment failed',
          'CallbackMetadata': {
            'Item': [
              {'Name': 'Amount', 'Value': amount},
              {'Name': 'MpesaReceiptNumber', 'Value': success ? 'RCP${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}' : ''},
              {'Name': 'TransactionDate', 'Value': DateTime.now().millisecondsSinceEpoch},
              {'Name': 'PhoneNumber', 'Value': phone},
            ],
          },
        },
      },
    };
  }
}
