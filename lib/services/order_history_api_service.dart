import 'dart:convert';

import 'package:GraBiTT/models/order_history_item.dart';
import 'package:http/http.dart' as http;

const String _baseUrl = 'https://grabitt.in';

String _cleanResponse(String body) {
  return body.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}

Future<List<OrderHistoryItem>> getOrderHistoryByUser(String userId) async {
  if (userId.trim().isEmpty) return [];
  try {
    final uri = Uri.parse('$_baseUrl/WebService.asmx/GetOrderHistory').replace(
      queryParameters: {'UserID': userId},
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) return [];
    final cleaned = _cleanResponse(response.body);
    if (cleaned.isEmpty || cleaned.toLowerCase() == 'fail') return [];
    final decoded = json.decode(cleaned);
    print(decoded);
    if (decoded is! List) return [];
    return decoded
        .map((e) => OrderHistoryItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  } catch (_) {
    return [];
  }
}

Future<bool> submitRiderRating({
  required String orderId,
  required String rating,
  required String note,
}) async {
  if (orderId.trim().isEmpty || rating.trim().isEmpty) return false;
  try {
    final uri = Uri.parse('$_baseUrl/WebService.asmx/SubmitRiderRating').replace(
      queryParameters: {
        'OrderID': orderId.trim(),
        'Rating': rating.trim(),
        'Note': note.trim(),
      },
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) return false;
    final cleaned = _cleanResponse(response.body);
    return cleaned.toLowerCase() == 'success';
  } catch (_) {
    return false;
  }
}
