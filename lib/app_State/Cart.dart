import 'package:flutter/cupertino.dart';

import '../Classes/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get total => product.discountPrice * quantity;
}
class CartService extends ChangeNotifier {
  static final CartService instance = CartService._();
  CartService._();

  final List<CartItem> items = [];
  bool _shouldAnimateCart = false;

  double get subtotal => items.fold(
      0, (sum, item) => sum + item.product.discountPrice * item.quantity);

  int get count => items.fold(0, (sum, item) => sum + item.quantity);

  bool get shouldAnimateCart => _shouldAnimateCart;

  void triggerCartAnimation() {
    _shouldAnimateCart = true;
    notifyListeners();
    // Reset after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _shouldAnimateCart = false;
      notifyListeners();
    });
  }

  void addItem(Product product) {
    final index =
    items.indexWhere((e) => e.product.id == product.id);

    if (index >= 0) {
      items[index].quantity++;
    } else {
      items.add(CartItem(product: product, quantity: 1));
    }

    notifyListeners(); // 🔥 updates cart page & bottom badge
  }
  void increase(CartItem item) {
    item.quantity++;
    notifyListeners();
  }

  void decrease(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      items.remove(item);
    }
    notifyListeners();
  }

  void remove(CartItem item) {
    items.remove(item);
    notifyListeners();
  }
}
