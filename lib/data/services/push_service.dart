import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class PushService {
  // Base URL of the Supabase Edge Functions host, injected at build time.
  static const String _envBase = String.fromEnvironment('SUPABASE_FUNCTIONS_URL');

  Future<void> send({
    required String recipientUid,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    final base = _envBase;
    if (base.isEmpty) return;
    try {
      await http.post(
        Uri.parse('$base/send-push'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'recipientUid': recipientUid,
          'title': title,
          'body': body,
          'data': data,
        }),
      );
    } catch (_) {}
  }
}

final pushServiceProvider = Provider<PushService>((ref) => PushService());