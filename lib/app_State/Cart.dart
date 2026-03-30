import 'dart:convert';

import 'package:GraBiTT/models/product.dart';
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
    if (productJson == null || productJson is! Map<String, dynamic>) return null;
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
  bool _shouldAnimateCart = false;

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.total);

  int get count => items.fold(0, (sum, item) => sum + item.quantity);

  bool get shouldAnimateCart => _shouldAnimateCart;

  Future<Map<String, String>> getUserContext() async {
    final user = await AuthService.instance.getSavedUser();

    return {
      "userId": user?['ID']?.toString() ?? '',
      "macId": "DEVICE123", // TODO: replace with real device ID
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

  void addItem(Product product) async {
    final ctx = await getUserContext();
    await CartApiService.addToCart(
      userId: ctx['userId']!,
      macId: ctx['macId']!,
      productId: product.id.toString(),
    );
    final index = items.indexWhere((e) => e.product.id == product.id);
    if (index >= 0) {
      items[index].quantity++;
    } else {
      items.add(CartItem(product: product, quantity: 1));
    }
    notifyListeners();
    _saveToStorage();
  }

  void increase(CartItem item) async{
    if (item.product != null) {
      await CartApiService.increaseQty(item.product.id!);
    }
    item.quantity++;
    notifyListeners();
    _saveToStorage();
  }

  void decrease(CartItem item) async{
    if (item.product != null) {
      await CartApiService.decreaseQty(item.product.id!);
    }
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      items.remove(item);
    }
    notifyListeners();
    _saveToStorage();
  }

  void remove(CartItem item) async{
    if (item.product != null) {
      await CartApiService.removeItem(item.product.id!);
    }
    items.remove(item);
    notifyListeners();
    _saveToStorage();
  }

  Future<void> syncCartFromServer() async {
    final ctx = await getUserContext();

    final response = await CartApiService.getCart(
      userId: ctx['userId']!,
      macId: ctx['macId']!,
      lang: "en",
    );

    if (response == null) return;

    items.clear();

    for (var item in response) {
      final product = Product.fromJson(item);

      items.add(
        CartItem(
          product: product,
          quantity: int.tryParse(item['Qty'].toString()) ?? 1,
          cartId: item['ID'].toString(), // 🔥 CRITICAL
        ),
      );
    }

    notifyListeners();
    _saveToStorage();
  }

  /// Clears cart and persists (e.g. after order placed).
  void clearCart() {
    items.clear();
    notifyListeners();
    _saveToStorage();
  }
}
