import 'dart:convert';

import 'package:GraBiTT/models/product.dart';
import 'package:GraBiTT/services/device_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/cart_api_service.dart';

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

  // ===================== CHANGE =====================
  // Prevent fast multiple taps issue
  final Set<String> _updatingProducts = {};

  bool _shouldAnimateCart = false;
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
  String _handlingFeeText = "";

  double _packagingFee = 0.0;

  double _finalTotal = 0.0;
  bool _isSyncingCart = false;

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

  double get finalTotal => _finalTotal > 0 ? _finalTotal : subtotal;

  bool get isSyncingCart => _isSyncingCart;

  int get count => items.fold(0, (sum, item) => sum + item.quantity);

  bool get shouldAnimateCart => _shouldAnimateCart;

  // ===================== CHANGE =====================
  bool isProductUpdating(String productId) {
    return _updatingProducts.contains(productId);
  }

  Future<Map<String, String>> getUserContext() async {
    final user = await AuthService.instance.getSavedUser();
    final deviceId = await DeviceService.instance.getDeviceId();

    return {
      "userId": user?['ID']?.toString() ?? '',
      "macId": deviceId,
    };
  }

  /// Call once at app start to restore cart from storage.
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
    } catch (_) {
      // ignore storage errors
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = items.map((e) => e.toJson()).toList();
      await prefs.setString(_cartStorageKey, jsonEncode(list));
    } catch (_) {}
  }

  void triggerCartAnimation() {
    _shouldAnimateCart = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 100), () {
      _shouldAnimateCart = false;
      notifyListeners();
    });
  }

  // void addItem(Product product) async {
  //   // final ctx = await getUserContext();
  //   // await CartApiService.addToCart(
  //   //   userId: ctx['userId']!,
  //   //   macId: ctx['macId']!,
  //   //   productId: product.id.toString(),
  //   // );
  //   final index = items.indexWhere((e) => e.product.id == product.id);
  //   if (index >= 0) {
  //     items[index].quantity++;
  //   } else {
  //     items.add(CartItem(product: product, quantity: 1));
  //   }
  //   final price = double.tryParse(product.discountPrice.toString()) ?? 0.0;

  //   _cartTotal += price;
  //   _finalTotal += price;
  //   notifyListeners();
  //   _saveToStorage();

  //   await _syncAddToServer(product);
  //   await syncCartFromServer();
  // }

  // ===================== CHANGE =====================
// OLD: Future<void> addItem(Product product)
// NEW: return backend response for UI toast
  Future<Map?> addItem(Product product) async {
    final id = product.id.toString();
    // prevent double tap
    if (_updatingProducts.contains(id)) return null;
    _updatingProducts.add(id);
    // notifyListeners();

    try {
      final index = items.indexWhere((e) => e.product.id == product.id);

      if (index >= 0) {
        items[index].quantity++;
      } else {
        items.add(CartItem(product: product, quantity: 1));
      }

      final price = double.tryParse(product.discountPrice.toString()) ?? 0.0;

      _cartTotal += price;
      _finalTotal += price;

      notifyListeners();
      _saveToStorage();

      // ===================== CHANGE =====================
      // capture API response
      final response = await _syncAddToServer(product);
      await syncCartFromServer();

      return response; // <-- UI ke liye message return
    } finally {
      _updatingProducts.remove(id);
      notifyListeners();
    }
  }

  // Future<void> _syncAddToServer(Product product) async {
  //   try {
  //     final ctx = await getUserContext();

  //     await CartApiService.addToCart(
  //       userId: ctx['userId']!,
  //       macId: ctx['macId']!,
  //       productId: product.id.toString(),
  //     );
  //   } catch (_) {}
  // }

// ===================== CHANGE =====================
// OLD: Future<void>
// NEW: return Map response for toast message
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
          return {"status": "error", "message": res};
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // void increase(CartItem item) async {
  //   // final apiId = item.cartId ?? item.product.id;
  //   // await CartApiService.increaseQty(apiId);
  //   item.quantity++;
  //   final price = double.tryParse(item.product.discountPrice.toString()) ?? 0.0;
  //   _cartTotal += price;
  //   _finalTotal += price;
  //   notifyListeners();
  //   _saveToStorage();
  //   _syncIncrease(item);
  //   // await syncCartFromServer();
  // }

  // ===================== CHANGE =====================
  // Added fast tap prevention for increase qty
  Future<void> increase(CartItem item) async {
    final id = item.product.id.toString();

    if (_updatingProducts.contains(id)) return;
    _updatingProducts.add(id);

    try {
      item.quantity++;

      final price =
          double.tryParse(item.product.discountPrice.toString()) ?? 0.0;

      _cartTotal += price;
      _finalTotal += price;

      notifyListeners();
      _saveToStorage();

      await _syncIncrease(item);
    } finally {
      _updatingProducts.remove(id);
      notifyListeners();
    }
  }

  Future<void> _syncIncrease(CartItem item) async {
    try {
      if (item.cartId == null) {
        await syncCartFromServer();
      }
      final apiId = item.cartId;
      if (apiId == null) return;
      await CartApiService.increaseQty(apiId);
    } catch (_) {}
  }

  // void decrease(CartItem item) async {
  //   // final apiId = item.cartId ?? item.product.id;
  //   // await CartApiService.decreaseQty(apiId);
  //   final price = double.tryParse(item.product.discountPrice.toString()) ?? 0.0;
  //   if (item.quantity > 1) {
  //     item.quantity--;
  //     _cartTotal -= price;
  //     _finalTotal -= price;
  //   } else {
  //     _cartTotal -= price;
  //     _finalTotal -= price;
  //     items.remove(item);
  //   }
  //   if (_cartTotal < 0) {
  //     _cartTotal = 0;
  //   }
  //   if (_finalTotal < 0) {
  //     _finalTotal = 0;
  //   }
  //   notifyListeners();
  //   _saveToStorage();
  //   _syncDecrease(item);
  //   // await syncCartFromServer();
  // }

  // ===================== CHANGE =====================
  // Added fast tap prevention for decrease qty
  Future<void> decrease(CartItem item) async {
    final id = item.product.id.toString();

    if (_updatingProducts.contains(id)) return;
    _updatingProducts.add(id);

    try {
      final price =
          double.tryParse(item.product.discountPrice.toString()) ?? 0.0;

      if (item.quantity > 1) {
        item.quantity--;
        _cartTotal -= price;
        _finalTotal -= price;
      } else {
        _cartTotal -= price;
        _finalTotal -= price;
        items.remove(item);
      }

      if (_cartTotal < 0) {
        _cartTotal = 0;
      }

      if (_finalTotal < 0) {
        _finalTotal = 0;
      }

      notifyListeners();
      _saveToStorage();

      await _syncDecrease(item);
    } finally {
      _updatingProducts.remove(id);
      notifyListeners();
    }
  }

  Future<void> _syncDecrease(CartItem item) async {
    try {
      if (item.cartId == null) {
        await syncCartFromServer();
      }
      final apiId = item.cartId;
      if (apiId == null) return;
      await CartApiService.decreaseQty(apiId);
    } catch (_) {}
  }

  void remove(CartItem item) async {
    // final apiId = item.cartId ?? item.product.id;
    // await CartApiService.removeItem(apiId);
    final price = double.tryParse(item.product.discountPrice.toString()) ?? 0.0;
    _cartTotal -= (price * item.quantity);
    _finalTotal -= (price * item.quantity);
    if (_cartTotal < 0) {
      _cartTotal = 0;
    }
    if (_finalTotal < 0) {
      _finalTotal = 0;
    }
    items.remove(item);
    notifyListeners();
    _saveToStorage();
    _syncRemove(item);
    // await syncCartFromServer();
  }

  Future<void> _syncRemove(CartItem item) async {
    try {
      if (item.cartId == null) {
        await syncCartFromServer();
      }
      final apiId = item.cartId;
      if (apiId == null) return;
      await CartApiService.removeItem(apiId);
    } catch (_) {}
  }

  Future<void> syncCartFromServer() async {
    _isSyncingCart = true;
    notifyListeners();
    try {
      final ctx = await getUserContext();

      final response = await CartApiService.getCart(
        userId: ctx['userId']!,
        macId: ctx['macId']!,
        lang: "en",
      );

      if (response == null) return;

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

      _handlingFeeText = response['HandlingFeeText']?.toString() ?? "";

      _packagingFee = _toDouble(response['PackagingFee']);

      _finalTotal = _toDouble(response['FinalTotal']);

      final rawItems = response['CartItems'];
      if (rawItems is List) {
        for (final rawItem in rawItems) {
          if (rawItem is! Map) continue;
          final item = Map<String, dynamic>.from(rawItem);
          final product = Product.fromJson({
            'ProductID': item['ProductID']?.toString() ?? '',
            'ProductName': item['ProductName']?.toString() ?? '',
            'CategoryName': item['CategoryName']?.toString() ?? '',
            'OriginalPrice': item['OriginalPrice']?.toString() ?? '0',
            'DiscountPrice': item['DiscountPrice']?.toString() ?? '0',
            'ProductImage':
                CartApiService.resolveImageUrl(item['Image']?.toString() ?? ''),
            'Image1': '',
            'Image2': '',
            'Image3': '',
            'Image4': '',
            'Image5': '',
          });

          items.add(
            CartItem(
              product: product,
              quantity: int.tryParse(item['Quantity']?.toString() ?? '1') ?? 1,
              cartId: item['ID']?.toString(),
            ),
          );
        }
      }
    } finally {
      _isSyncingCart = false;
      notifyListeners();
    }
    _saveToStorage();
  }

  /// Clears cart and persists (e.g. after order placed).
  void clearCart() {
    items.clear();
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
    _handlingFeeText = "";

    _packagingFee = 0.0;

    _finalTotal = 0.0;
    notifyListeners();
    _saveToStorage();
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }
}
