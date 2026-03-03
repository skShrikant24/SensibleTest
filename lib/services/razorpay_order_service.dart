import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String _baseUrl = 'https://grabitt.in';

/// Cleans XML-wrapped response and returns inner string (e.g. JSON).
String _cleanResponse(String body) {
  return body.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}

/// Creates a Razorpay order via backend. Backend must call Razorpay Create Order API
/// (POST /v1/orders) with [amountPaise] and return the order id.
///
/// [amountPaise] – amount in paise (e.g. ₹100 = 10000).
/// Returns the order_id (e.g. "order_RB58MiP5SPFYyM") or null on error.
///
/// Expected backend: GET or POST CreateRazorpayOrder with amount (paise).
/// Response: plain "order_xxx" or JSON {"id":"order_xxx"} / {"order_id":"order_xxx"}.
Future<String?> createRazorpayOrder(int amountPaise) async {
  if (amountPaise < 100) return null; // Razorpay minimum INR 1
  try {
    final uri =
        Uri.parse('$_baseUrl/webservice.asmx/CreateRazorpayOrder').replace(
      queryParameters: {'amount': amountPaise.toString()},
    );
    debugPrint(
        '[Razorpay] Create order request: amount=$amountPaise, url=$uri');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      debugPrint(
          '[Razorpay] Create order failed: status=${response.statusCode}, body=${response.body}');
      return null;
    }
    final cleaned = _cleanResponse(response.body);
    debugPrint('[Razorpay] Create order raw response: $cleaned');
    if (cleaned.isEmpty || cleaned.toLowerCase() == 'fail') {
      return null;
    }
    // Try JSON first
    try {
      final decoded = json.decode(cleaned);
      if (decoded is Map<String, dynamic>) {
        final id = decoded['id'] ?? decoded['order_id'];
        final s = id?.toString().trim();
        if (s != null && s.isNotEmpty && s.toLowerCase().startsWith('order_')) {
          debugPrint('[Razorpay] Parsed backend order_id: $s');
          return s;
        }
      }
    } catch (_) {}
    // Plain text order_id
    final trimmed = cleaned.trim();
    if (trimmed.toLowerCase().startsWith('order_')) {
      debugPrint('[Razorpay] Parsed backend order_id: $trimmed');
      return trimmed;
    }
    return null;
  } catch (e) {
    debugPrint('[Razorpay] Create order exception: $e');
    return null;
  }
}
