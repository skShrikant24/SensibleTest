import 'dart:convert';
import 'package:grabitt/utils/app_logger.dart';
import 'package:http/http.dart' as http;

const String _tag = 'CartApiService';

class CartApiService {
  static const String baseUrl = "https://grabitt.in/webservice.asmx";
  static const String _imageBaseUrl = "https://grabitt.in";

  static Future<dynamic> _get(String endpoint) async {
    final url = '$baseUrl/$endpoint';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        AppLogger.w(_tag, '_get: HTTP ${response.statusCode} — $url');
        return null;
      }

      final body = response.body;

      if (body.contains('<string')) {
        final cleaned = body.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        try {
          return jsonDecode(cleaned);
        } catch (_) {
          return cleaned; // fallback: return raw string
        }
      }

      return jsonDecode(body);
    } catch (e, st) {
      AppLogger.e(_tag, '_get failed — $url', e, st);
      return null;
    }
  }

  /// Add to cart
  static Future addToCart({
    required String userId,
    required String macId,
    required String productId,
  }) {
    return _get("AddToCart?UserID=$userId&MacID=$macId&ProductID=$productId");
  }

  /// Get cart
  static Future<Map<String, dynamic>?> getCart({
    required String userId,
    required String macId,
    required String lang,
    String? addressId,
  }) async {
    final response = await _get(
      "GetCart?UserID=$userId&MacID=$macId&lang=$lang&AddressID=$addressId",
    );
    if (response == null) return null;

    if (response is Map<String, dynamic>) return response;

    if (response is String) {
      final trimmed = response.trim();
      AppLogger.d(_tag, 'getCart: raw string response → "$trimmed"');
      if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return null;
      if (trimmed.startsWith("{") && trimmed.endsWith("}")) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map<String, dynamic>) return decoded;
        } catch (e, st) {
          AppLogger.e(_tag, 'getCart: failed to parse string response', e, st);
          return null;
        }
      }
    }

    AppLogger.w(
        _tag, 'getCart: unexpected response type — ${response.runtimeType}');
    return null;
  }

  /// Increase qty
  static Future increaseQty(String id) {
    return _get("IncreaseCartQty?ID=$id");
  }

  /// Decrease qty
  static Future decreaseQty(String id) {
    return _get("DecreaseCartQty?ID=$id");
  }

  /// Remove item
  static Future removeItem(String id) {
    return _get("RemoveCartItem?ID=$id");
  }

  /// Clear cart
  static Future clearCart({
    required String userId,
    required String macId,
  }) {
    return _get("ClearCart?UserID=$userId&MacID=$macId");
  }

  /// Place order
  static Future placeOrder({
    required String userId,
    required String macId,
    required String paymentMode,
    required String addressId,
  }) {
    return _get(
        "PlaceOrder?UserID=$userId&MacID=$macId&PaymentMode=$paymentMode&AddressID=$addressId");
  }

  static String resolveImageUrl(String rawImagePath) {
    final path = rawImagePath.trim();
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final normalizedPath = path
        .replaceFirst('~/', '')
        .replaceFirst('~', '')
        .replaceFirst(RegExp(r'^/+'), '');
    return "$_imageBaseUrl/$normalizedPath";
  }
}
