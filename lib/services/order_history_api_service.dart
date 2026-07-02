import 'dart:convert';

import 'package:grabitt/models/order_history_item.dart';
import 'package:http/http.dart' as http;

import '../utils/app_logger.dart';

const String _tag = 'OrderHistoryApiService';
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
    if (response.statusCode != 200) {
      AppLogger.w(_tag, 'getOrderHistoryByUser: HTTP ${response.statusCode}');
      return [];
    }
    final cleaned = _cleanResponse(response.body);
    if (cleaned.isEmpty || cleaned.toLowerCase() == 'fail') return [];
    final decoded = json.decode(cleaned);
    // print(decoded);
    if (decoded is! List) {
      AppLogger.w(_tag, 'getOrderHistoryByUser: unexpected response type');
      return [];
    }
    return decoded
        .map((e) => OrderHistoryItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  } catch (e, st) {
    AppLogger.e(
        _tag, 'getOrderHistoryByUser: failed to fetch order history', e, st);
    return [];
  }
}

Future<OrderHistoryItem?> getOrderDetails(String orderId) async {
  if (orderId.trim().isEmpty) return null;

  try {
    final uri = Uri.parse(
      '$_baseUrl/Webservice.asmx/GetOrderDetails',
    ).replace(
      queryParameters: {
        'OrderID': orderId,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      AppLogger.w(_tag, 'getOrderDetails: HTTP ${response.statusCode}');
      return null;
    }

    final cleaned = _cleanResponse(response.body);

    if (cleaned.isEmpty || cleaned.toLowerCase() == 'fail') return null;

    final decoded = json.decode(cleaned);

    // API returns single object
    if (decoded is! Map<String, dynamic>) {
      AppLogger.w(_tag, 'getOrderDetails: unexpected response type');
      return null;
    }

    return OrderHistoryItem.fromJson(decoded);
  } catch (e, st) {
    AppLogger.e(_tag, 'getOrderDetails failed', e, st);
    return null;
  }
}

Future<bool> submitRiderRating({
  required String orderId,
  required String rating,
  required String note,
}) async {
  if (orderId.trim().isEmpty || rating.trim().isEmpty) return false;
  try {
    final trimmedNote = note.trim();
    final uri =
        Uri.parse('$_baseUrl/WebService.asmx/SubmitRiderRating').replace(
      queryParameters: {
        'OrderID': orderId.trim(),
        'Rating': rating.trim(),
        // Server throws "Missing parameter: Note" on a truly empty value
        // for some ASMX configurations. Send a single space as a safe
        // non-empty placeholder when the user leaves the note blank.
        'Note': trimmedNote.isEmpty ? ' ' : trimmedNote,
      },
    );
    AppLogger.d(_tag, 'submitRiderRating: GET $uri');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      AppLogger.w(_tag,
          'submitRiderRating: HTTP ${response.statusCode} — body: ${response.body}');
      return false;
    }
    final cleaned = _cleanResponse(response.body);
    final success = cleaned.toLowerCase() == 'success';
    if (!success) {
      AppLogger.w(_tag, 'submitRiderRating: unexpected response: $cleaned');
    }
    return success;
  } catch (e, st) {
    AppLogger.e(_tag, 'submitRiderRating failed', e, st);
    return false;
  }
}
