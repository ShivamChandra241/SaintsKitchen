import 'package:flutter/material.dart';
import 'dart:math';
import '../services/database_service.dart';
import '../models/wallet_transaction.dart';

class UserProvider extends ChangeNotifier {
  String _name = "";
  String _id = "";
  bool _isLoggedIn = false;
  double _walletBalance = 0.0;
  List<WalletTransaction> _transactions = [];

  String get name => _name;
  String get id => _id;
  bool get isLoggedIn => _isLoggedIn;
  double get walletBalance => _walletBalance;
  List<WalletTransaction> get transactions => _transactions;

  UserProvider() {
    _loadUser();
  }

  void _loadUser() {
    _isLoggedIn = DatabaseService.user.get('isLoggedIn', defaultValue: false);
    if (_isLoggedIn) {
      _name = DatabaseService.user.get('name', defaultValue: "");
      _id = DatabaseService.user.get('id', defaultValue: "");
      _walletBalance = DatabaseService.user.get('wallet', defaultValue: 0.0);
      _transactions = DatabaseService.transactions.values.toList().reversed.toList();
    }
    notifyListeners();
  }

  Future<void> login(String name, String id) async {
    _name = name;
    _id = id;
    _isLoggedIn = true;
    _walletBalance = DatabaseService.user.get('wallet', defaultValue: 0.0);

    await DatabaseService.user.put('isLoggedIn', true);
    await DatabaseService.user.put('name', name);
    await DatabaseService.user.put('id', id);
    if (!DatabaseService.user.containsKey('wallet')) {
       await DatabaseService.user.put('wallet', 0.0);
    }
    _loadUser(); // Refresh transactions
  }

  Future<void> logout() async {
    await DatabaseService.user.put('isLoggedIn', false);
    _isLoggedIn = false;
    _name = "";
    _id = "";
    _walletBalance = 0.0;
    _transactions = [];
    notifyListeners();
  }

  Future<void> addMoney(double amount, String method, String meta) async {
    _walletBalance += amount;
    await DatabaseService.user.put('wallet', _walletBalance);

    final txn = WalletTransaction(
      "TX-${Random().nextInt(99999)}",
      "Deposit",
      amount,
      true,
      method,
      DateTime.now(),
      meta: meta,
    );

    await DatabaseService.transactions.add(txn);
    _transactions.insert(0, txn);
    notifyListeners();
  }

  Future<bool> deductMoney(double amount, String orderId) async {
    if (_walletBalance < amount) return false;

    _walletBalance -= amount;
    await DatabaseService.user.put('wallet', _walletBalance);

    final txn = WalletTransaction(
      "ORD-${Random().nextInt(99999)}",
      "Food Order",
      amount,
      false,
      "Wallet",
      DateTime.now(),
      meta: orderId,
    );

    await DatabaseService.transactions.add(txn);
    _transactions.insert(0, txn);
    notifyListeners();
    return true;
  }
}
