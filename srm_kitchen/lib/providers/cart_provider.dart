import 'package:flutter/material.dart';
import 'package:srm_kitchen/models/food_item.dart';
import 'package:srm_kitchen/models/cart_item.dart';
import 'package:srm_kitchen/models/order.dart';
import 'package:srm_kitchen/services/database_service.dart';
import 'dart:math';

class CartProvider extends ChangeNotifier {
  List<CartItem> _cart = [];
  List<Order> _history = [];
  double _discount = 0.0;

  List<CartItem> get cart => _cart;
  List<Order> get history => _history;
  double get discount => _discount;

  double get subtotal => _cart.fold(0, (s, i) => s + i.totalPrice);
  double get total => max(0, subtotal - _discount);

  CartProvider() {
    _loadData();
  }

  void _loadData() {
    _cart = DatabaseService.cart.values.toList();
    _history = DatabaseService.orders.values.toList().reversed.toList();
    notifyListeners();
  }

  void addToCart(FoodItem item, FoodVariant? variant, int qty) {
    final existingIndex = _cart.indexWhere((c) =>
        c.item.id == item.id &&
        ((c.selectedVariant == null && variant == null) ||
            (c.selectedVariant?.name == variant?.name)));

    if (existingIndex != -1) {
      _cart[existingIndex].quantity += qty;
      DatabaseService.cart.putAt(existingIndex, _cart[existingIndex]);
    } else {
      final newItem = CartItem(item, qty, selectedVariant: variant);
      _cart.add(newItem);
      DatabaseService.cart.add(newItem);
    }
    notifyListeners();
  }

  void updateQuantity(CartItem item, int delta) {
    final index = _cart.indexOf(item);
    if (index == -1) return;

    item.quantity += delta;
    if (item.quantity <= 0) {
      _cart.removeAt(index);
      DatabaseService.cart.deleteAt(index);
    } else {
      DatabaseService.cart.putAt(index, item);
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    DatabaseService.cart.clear();
    _discount = 0.0;
    notifyListeners();
  }

  bool applyCoupon(String code) {
    if (code.toUpperCase() == "SAINTS50") {
      _discount = 50.0;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<Order> placeOrder(double paidAmount) async {
    final orderId = "SK-${Random().nextInt(9999)}";
    final newOrder = Order(
      orderId,
      List.from(_cart),
      subtotal,
      _discount,
      paidAmount,
      DateTime.now(),
    );

    _history.insert(0, newOrder);
    await DatabaseService.orders.add(newOrder);

    // Clear cart but keep history
    _cart.clear();
    await DatabaseService.cart.clear();
    _discount = 0.0;

    notifyListeners();
    return newOrder;
  }

  void rateOrder(Order order, int rating) {
    order.rating = rating;
    // Since we didn't extend HiveObject, we need to find key or save manually.
    // Simpler: just notify listeners as it updates reference in memory.
    // To persist:
    final key = DatabaseService.orders.keys.firstWhere((k) => DatabaseService.orders.get(k)?.id == order.id, orElse: () => null);
    if (key != null) {
      DatabaseService.orders.put(key, order);
    }
    notifyListeners();
  }
}
