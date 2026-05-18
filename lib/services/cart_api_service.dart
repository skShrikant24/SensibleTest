import 'dart:convert';
import 'package:http/http.dart' as http;

class CartApiService {
  static const String baseUrl = "https://grabitt.in/webservice.asmx";
  static const String _imageBaseUrl = "https://grabitt.in";

  static Future<dynamic> _get(String endpoint) async {
    try {
      final url = "$baseUrl/$endpoint";
      final response = await http.get(Uri.parse(url));

      print(url);
      print(response.body);

      if (response.statusCode == 200) {
        final body = response.body;

     // ===================== CHANGE =====================
      // OLD: only string "Success"
      // NEW: handle JSON inside XML response safely
        if (body.contains("<string")) {
          final cleaned = body
              .replaceAll(RegExp(r'<[^>]*>'), '') // remove XML tags
              .trim();

          try {
            final decoded = jsonDecode(cleaned);
            return decoded; // <-- Map return hoga
          } catch (_) {
            return cleaned; // fallback string
          }
        }

        // fallback JSON (if any API returns JSON)
        return jsonDecode(body);
      } else {
        throw Exception("API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("API ERROR: $e");
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

    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is String) {
      final trimmed = response.trim();
      if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return null;
      if (trimmed.startsWith("{") && trimmed.endsWith("}")) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map<String, dynamic>) return decoded;
        } catch (_) {
          return null;
        }
      }
    }

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
