import 'package:hive_flutter/hive_flutter.dart';
import '../models/food_item.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/wallet_transaction.dart';

class DatabaseService {
  static const String boxUser = 'userBox';
  static const String boxCart = 'cartBox';
  static const String boxOrders = 'ordersBox';
  static const String boxTransactions = 'transactionsBox';
  static const String boxFavorites = 'favoritesBox';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(FoodVariantAdapter());
    Hive.registerAdapter(FoodItemAdapter());
    Hive.registerAdapter(CartItemAdapter());
    Hive.registerAdapter(WalletTransactionAdapter());
    Hive.registerAdapter(OrderAdapter());

    // Open Boxes
    await Hive.openBox(boxUser);
    await Hive.openBox<CartItem>(boxCart);
    await Hive.openBox<Order>(boxOrders);
    await Hive.openBox<WalletTransaction>(boxTransactions);
    await Hive.openBox<String>(boxFavorites);
  }

  static Box get user => Hive.box(boxUser);
  static Box<CartItem> get cart => Hive.box<CartItem>(boxCart);
  static Box<Order> get orders => Hive.box<Order>(boxOrders);
  static Box<WalletTransaction> get transactions => Hive.box<WalletTransaction>(boxTransactions);
  static Box<String> get favorites => Hive.box<String>(boxFavorites);
}
