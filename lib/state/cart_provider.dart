import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// One cart line.
class CartEntry {
  final Product product;
  int quantity;

  CartEntry({required this.product, this.quantity = 1});

  double get lineTotal => product.price * quantity;
}

/// Session cart for the storefront.
class CartProvider extends ChangeNotifier {
  final Map<String, CartEntry> _items = {};

  List<CartEntry> get items => List.unmodifiable(_items.values);
  bool get isEmpty => _items.isEmpty;
  int get itemCount =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal =>
      _items.values.fold(0.0, (sum, item) => sum + item.lineTotal);

  void add(Product product, {int quantity = 1}) {
    final existing = _items[product.id];
    if (existing != null) {
      existing.quantity += quantity;
    } else {
      _items[product.id] = CartEntry(product: product, quantity: quantity);
    }
    notifyListeners();
  }

  void increase(String productId) {
    final item = _items[productId];
    if (item != null) {
      item.quantity++;
      notifyListeners();
    }
  }

  void decrease(String productId) {
    final item = _items[productId];
    if (item == null) return;
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void remove(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// Convert to order items for checkout.
  List<OrderItem> toOrderItems() => _items.values
      .map(
        (e) => OrderItem(
          productId: e.product.id,
          productName: e.product.name,
          price: e.product.price,
          quantity: e.quantity,
        ),
      )
      .toList();
}
