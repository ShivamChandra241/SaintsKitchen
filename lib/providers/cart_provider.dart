import 'package:flutter/material.dart';
import 'package:srm_kitchen/models/food_item.dart';
import 'package:srm_kitchen/models/cart_item.dart';
import 'package:srm_kitchen/models/order.dart';
import 'package:srm_kitchen/services/database_service.dart';
import 'dart:math';

enum CheckoutState { idle, loading, success, error }

class CartProvider extends ChangeNotifier {
  List<CartItem> _cart = [];
  List<Order> _history = [];
  double _discount = 0.0;
  CheckoutState _checkoutState = CheckoutState.idle;

  List<CartItem> get cart => _cart;
  List<Order> get history => _history;
  double get discount => _discount;
  CheckoutState get checkoutState => _checkoutState;

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

  void reorder(Order order) {
    for (var item in order.items) {
      addToCart(item.item, item.selectedVariant, item.quantity);
    }
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
    if (code.toUpperCase() == "SRM50" || code.toUpperCase() == "SAINTS50") {
      _discount = 50.0;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> checkout(double paidAmount) async {
    if (_cart.isEmpty) return false;

    try {
      _checkoutState = CheckoutState.loading;
      notifyListeners();

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

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

      _checkoutState = CheckoutState.success;
      notifyListeners();

      // Wait for success animation to play in UI before clearing
      await Future.delayed(const Duration(seconds: 2));

      _cart.clear();
      await DatabaseService.cart.clear();
      _discount = 0.0;
      _checkoutState = CheckoutState.idle;
      notifyListeners();

      return true;
    } catch (e) {
      _checkoutState = CheckoutState.error;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 2));
      _checkoutState = CheckoutState.idle;
      notifyListeners();
      return false;
    }
  }

  void rateOrder(Order order, int rating) {
    order.rating = rating;
    final key = DatabaseService.orders.keys.firstWhere((k) => DatabaseService.orders.get(k)?.id == order.id, orElse: () => null);
    if (key != null) {
      DatabaseService.orders.put(key, order);
    }
    notifyListeners();
  }
}
