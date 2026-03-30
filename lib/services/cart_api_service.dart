import 'dart:convert';
import 'package:http/http.dart' as http;

class CartApiService {
  static const String baseUrl = "https://grabitt.in/webservice.asmx";

  static Future<dynamic> _get(String endpoint) async {
    try {
      final url = "$baseUrl/$endpoint";
      final response = await http.get(Uri.parse(url));

      print(url);
      print(response.body);

      if (response.statusCode == 200) {
        final body = response.body;

        // ✅ Handle XML response
        if (body.contains("<string")) {
          final value = body
              .replaceAll(RegExp(r'<[^>]*>'), '') // remove XML tags
              .trim();

          return value; // "Success"
        }

        // ✅ fallback JSON (if any API returns JSON)
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
    return _get(
        "AddToCart?UserID=$userId&MacID=$macId&ProductID=$productId");
  }

  /// Get cart
  static Future getCart({
    required String userId,
    required String macId,
    required String lang,
  }) {
    return _get(
        "GetCart?UserID=$userId&MacID=$macId&lang=$lang");
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
}