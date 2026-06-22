import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:grabitt/models/product.dart';
import 'package:grabitt/services/auth_service.dart';
import 'package:grabitt/services/cart_api_service.dart';
import 'package:grabitt/services/device_service.dart';
import 'package:grabitt/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _tag = 'CartService';
const String _cartStorageKey = 'grabbit_cart';

class CartItem {
  final Product product;
  int quantity;
  String? cartId;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.cartId,
  });

  double get total =>
      (double.tryParse(product.discountPrice.toString()) ?? 0.0) * quantity;

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'quantity': quantity,
      };

  static CartItem? fromJson(Map<String, dynamic> json) {
    final productJson = json['product'];
    if (productJson == null || productJson is! Map<String, dynamic>) {
      return null;
    }
    try {
      final product = Product.fromJson(Map<String, dynamic>.from(productJson));
      final quantity = (json['quantity'] is int)
          ? json['quantity'] as int
          : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1;
      return CartItem(product: product, quantity: quantity);
    } catch (_) {
      return null;
    }
  }
}

class CartService extends ChangeNotifier {
  static final CartService instance = CartService._();
  CartService._();

  final List<CartItem> items = [];

  // Prevents fast multiple taps from firing duplicate API calls.
  final Set<String> _updatingProducts = {};

  bool _shouldAnimateCart = false;

  // Server-authoritative totals. Only set by syncCartFromServer().
  // Never manually incremented/decremented on local mutations.
  double _cartTotal = 0.0;
  double _deliveryCharge = 0.0;
  double _gst = 0.0;
  int _gstPercent = 0;
  bool _isNewUserDiscountApplied = false;
  int _newUserDiscountPercent = 0;
  double _newUserDiscountAmount = 0.0;
  bool _isEvenOrderDiscountApplied = false;
  int _evenOrderDiscountPercent = 0;
  double _evenOrderDiscountAmount = 0.0;
  double _serviceFee = 0.0;
  bool _isHandlingFeeApplied = false;
  double _handlingFee = 0.0;
  String _handlingFeeText = '';
  double _packagingFee = 0.0;
  double _finalTotal = 0.0;
  bool _isSyncingCart = false;
  String? _currentAddressId;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// Before the first server sync, falls back to a live local calculation so
  /// the UI always shows a reasonable value.
  double get subtotal => _cartTotal > 0
      ? _cartTotal
      : items.fold(0.0, (sum, item) => sum + item.total);

  double get deliveryCharge => _deliveryCharge;
  double get gst => _gst;
  int get gstPercent => _gstPercent;

  bool get isNewUserDiscountApplied => _isNewUserDiscountApplied;
  int get newUserDiscountPercent => _newUserDiscountPercent;
  double get newUserDiscountAmount => _newUserDiscountAmount;

  bool get isEvenOrderDiscountApplied => _isEvenOrderDiscountApplied;
  int get evenOrderDiscountPercent => _evenOrderDiscountPercent;
  double get evenOrderDiscountAmount => _evenOrderDiscountAmount;

  double get serviceFee => _serviceFee;

  bool get isHandlingFeeApplied => _isHandlingFeeApplied;
  double get handlingFee => _handlingFee;
  String get handlingFeeText => _handlingFeeText;

  double get packagingFee => _packagingFee;

  /// Falls back to subtotal until the server returns a FinalTotal.
  double get finalTotal => _finalTotal > 0 ? _finalTotal : subtotal;

  bool get isSyncingCart => _isSyncingCart;
  int get count => items.fold(0, (sum, item) => sum + item.quantity);
  bool get shouldAnimateCart => _shouldAnimateCart;

  bool isProductUpdating(String productId) =>
      _updatingProducts.contains(productId);

  // ---------------------------------------------------------------------------
  // User context
  // ---------------------------------------------------------------------------

  Future<Map<String, String>> getUserContext() async {
    final user = await AuthService.instance.getSavedUser();
    final deviceId = await DeviceService.instance.getDeviceId();
    return {
      'userId': user?['ID']?.toString() ?? '',
      'macId': deviceId,
    };
  }

  // ---------------------------------------------------------------------------
  // Local storage
  // ---------------------------------------------------------------------------

  /// Call once at app start to restore cart from local storage.
  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cartStorageKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw);
      if (list is! List) return;
      items.clear();
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          final item = CartItem.fromJson(e);
          if (item != null && item.quantity > 0) items.add(item);
        }
      }
      notifyListeners();
    } catch (e, st) {
      AppLogger.e(_tag, 'loadFromStorage failed', e, st);
      // Storage errors are non-fatal; cart starts empty.
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cartStorageKey,
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );
    } catch (e, st) {
      AppLogger.e(_tag, '_saveToStorage failed', e, st);
    }
  }

  // ---------------------------------------------------------------------------
  // Animation
  // ---------------------------------------------------------------------------

  void triggerCartAnimation() {
    _shouldAnimateCart = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 100), () {
      _shouldAnimateCart = false;
      notifyListeners();
    });
  }

  // ---------------------------------------------------------------------------
  // Cart mutations
  //
  // Pattern: optimistic update on `items` list only → notify UI → sync server.
  // Totals (_cartTotal, _finalTotal, etc.) are NEVER touched here;
  // syncCartFromServer() is the single place that sets them.
  // The `subtotal` getter provides a live local fallback until server responds.
  // ---------------------------------------------------------------------------

  /// Adds [product] to cart. Returns the backend response so the UI can show
  /// a toast (e.g. a server message or confirmation).
  Future<Map?> addItem(Product product) async {
    final id = product.id.toString();
    if (_updatingProducts.contains(id)) return null;
    _updatingProducts.add(id);

    try {
      final index = items.indexWhere((e) => e.product.id == product.id);
      if (index >= 0) {
        items[index].quantity++;
      } else {
        items.add(CartItem(product: product));
      }

      notifyListeners();
      _saveToStorage();

      final response = await _syncAddToServer(product);
      await syncCartFromServer(addressId: _currentAddressId);
      return response;
    } finally {
      _updatingProducts.remove(id);
      notifyListeners();
    }
  }

  Future<void> increase(CartItem item) async {
    final id = item.product.id.toString();
    if (_updatingProducts.contains(id)) return;
    _updatingProducts.add(id);

    try {
      item.quantity++;
      notifyListeners();
      _saveToStorage();
      await _syncIncrease(item);
    } finally {
      _updatingProducts.remove(id);
      notifyListeners();
    }
  }

  Future<void> decrease(CartItem item) async {
    final id = item.product.id.toString();
    if (_updatingProducts.contains(id)) return;
    _updatingProducts.add(id);

    try {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        items.remove(item);
      }
      notifyListeners();
      _saveToStorage();
      await _syncDecrease(item);
    } finally {
      _updatingProducts.remove(id);
      notifyListeners();
    }
  }

  Future<void> remove(CartItem item) async {
    items.remove(item);
    notifyListeners();
    _saveToStorage();
    await _syncRemove(item);
  }

  /// Clears all cart data and persists the empty state.
  void clearCart() {
    items.clear();
    _resetTotals();
    notifyListeners();
    _saveToStorage();
  }

  // ---------------------------------------------------------------------------
  // Server sync
  // ---------------------------------------------------------------------------

  Future<void> syncCartFromServer({String? addressId}) async {
    if (addressId != null && addressId.isNotEmpty) {
      _currentAddressId = addressId;
    }

    _isSyncingCart = true;
    notifyListeners();

    try {
      final ctx = await getUserContext();
      final userId = ctx['userId'] ?? '';
      final macId = ctx['macId'] ?? '';
      if (userId.isEmpty || macId.isEmpty) {
        AppLogger.w(_tag,
            'syncCartFromServer: userId or macId is empty — skipping sync');
        return;
      }

      final response = await CartApiService.getCart(
        userId: userId,
        macId: macId,
        lang: 'en',
        addressId: _currentAddressId ?? '',
      );
      if (response == null) {
        // AppLogger.w(_tag, 'syncCartFromServer: server returned null');
        // null = "Cart Empty" from server — clear local state silently.
        items.clear();
        _resetTotals();
        return;
      }

      items.clear();

      _cartTotal = _toDouble(response['CartTotal']);
      _deliveryCharge = _toDouble(response['DeliveryCharge']);
      _gst = _toDouble(response['GST']);
      _gstPercent =
          int.tryParse(response['GSTPercent']?.toString() ?? '0') ?? 0;

      _isNewUserDiscountApplied = response['IsNewUserDiscountApplied'] == true;
      _newUserDiscountPercent =
          int.tryParse(response['NewUserDiscountPercent']?.toString() ?? '0') ??
              0;
      _newUserDiscountAmount = _toDouble(response['NewUserDiscountAmount']);

      _isEvenOrderDiscountApplied =
          response['IsEvenOrderDiscountApplied'] == true;
      _evenOrderDiscountPercent = int.tryParse(
              response['EvenOrderDiscountPercent']?.toString() ?? '0') ??
          0;
      _evenOrderDiscountAmount = _toDouble(response['EvenOrderDiscountAmount']);

      _serviceFee = _toDouble(response['ServiceFee']);
      _isHandlingFeeApplied = response['IsHandlingFeeApplied'] == true;
      _handlingFee = _toDouble(response['HandlingFee']);
      _handlingFeeText = response['HandlingFeeText']?.toString() ?? '';
      _packagingFee = _toDouble(response['PackagingFee']);
      _finalTotal = _toDouble(response['FinalTotal']);

      final rawItems = response['CartItems'];
      if (rawItems is List) {
        for (final rawItem in rawItems) {
          if (rawItem is! Map) continue;
          final map = Map<String, dynamic>.from(rawItem);
          final product = Product.fromJson({
            'ProductID': map['ProductID']?.toString() ?? '',
            'ProductName': map['ProductName']?.toString() ?? '',
            'CategoryName': map['CategoryName']?.toString() ?? '',
            'OriginalPrice': map['OriginalPrice']?.toString() ?? '0',
            'DiscountPrice': map['DiscountPrice']?.toString() ?? '0',
            'ProductImage':
                CartApiService.resolveImageUrl(map['Image']?.toString() ?? ''),
            'Image1': '',
            'Image2': '',
            'Image3': '',
            'Image4': '',
            'Image5': '',
          });

          items.add(CartItem(
            product: product,
            quantity: int.tryParse(map['Quantity']?.toString() ?? '1') ?? 1,
            cartId: map['ID']?.toString(),
          ));
        }
      }
    } finally {
      _isSyncingCart = false;
      notifyListeners();
    }

    _saveToStorage();
  }

  // ---------------------------------------------------------------------------
  // Private — server sync helpers
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> _syncAddToServer(Product product) async {
    try {
      final ctx = await getUserContext();
      final res = await CartApiService.addToCart(
        userId: ctx['userId']!,
        macId: ctx['macId']!,
        productId: product.id.toString(),
      );
      if (res is Map<String, dynamic>) return res;
      if (res is String) {
        try {
          return jsonDecode(res);
        } catch (_) {
          return {'status': 'error', 'message': res};
        }
      }
      return null;
    } catch (e, st) {
      AppLogger.e(
          _tag, '_syncAddToServer failed for product ${product.id}', e, st);
      return null;
    }
  }

  Future<void> _syncIncrease(CartItem item) async {
    try {
      if (item.cartId == null) {
        AppLogger.w(
            _tag, '_syncIncrease: cartId is null — falling back to full sync');
        await syncCartFromServer(addressId: _currentAddressId);
        return;
      }
      await CartApiService.increaseQty(item.cartId!);
      await syncCartFromServer(addressId: _currentAddressId);
    } catch (e, st) {
      AppLogger.e(
          _tag, '_syncIncrease failed for cartId ${item.cartId}', e, st);
    }
  }

  Future<void> _syncDecrease(CartItem item) async {
    try {
      if (item.cartId == null) {
        AppLogger.w(
            _tag, '_syncDecrease: cartId is null — falling back to full sync');
        await syncCartFromServer(addressId: _currentAddressId);
        return;
      }
      await CartApiService.decreaseQty(item.cartId!);
      await syncCartFromServer(addressId: _currentAddressId);
    } catch (e, st) {
      AppLogger.e(
          _tag, '_syncDecrease failed for cartId ${item.cartId}', e, st);
    }
  }

  Future<void> _syncRemove(CartItem item) async {
    try {
      if (item.cartId == null) {
        AppLogger.w(
            _tag, '_syncRemove: cartId is null — falling back to full sync');
        await syncCartFromServer(addressId: _currentAddressId);
        return;
      }
      await CartApiService.removeItem(item.cartId!);
      await syncCartFromServer(addressId: _currentAddressId);
    } catch (e, st) {
      AppLogger.e(_tag, '_syncRemove failed for cartId ${item.cartId}', e, st);
    }
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  void _resetTotals() {
    _cartTotal = 0.0;
    _deliveryCharge = 0.0;
    _gst = 0.0;
    _gstPercent = 0;
    _isNewUserDiscountApplied = false;
    _newUserDiscountPercent = 0;
    _newUserDiscountAmount = 0.0;
    _isEvenOrderDiscountApplied = false;
    _evenOrderDiscountPercent = 0;
    _evenOrderDiscountAmount = 0.0;
    _serviceFee = 0.0;
    _isHandlingFeeApplied = false;
    _handlingFee = 0.0;
    _handlingFeeText = '';
    _packagingFee = 0.0;
    _finalTotal = 0.0;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }
}
