import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';

// --- DATA MODELS ---

class FoodVariant {
  final String name; 
  final double price;
  FoodVariant(this.name, this.price);
  Map<String, dynamic> toJson() => {'name': name, 'price': price};
  factory FoodVariant.fromJson(Map<String, dynamic> json) => FoodVariant(json['name'], json['price']);
}

class FoodItem {
  final String id;
  final String name;
  final String category;
  final double basePrice;
  final String imageUrl;
  final bool isVeg;
  final String description;
  final List<FoodVariant> variants;
  bool isFavorite;

  FoodItem(this.id, this.name, this.category, this.basePrice, this.imageUrl, this.isVeg, this.description, {this.variants = const [], this.isFavorite = false});

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'category': category, 'basePrice': basePrice,
    'imageUrl': imageUrl, 'isVeg': isVeg, 'description': description,
    'variants': variants.map((v) => v.toJson()).toList(), 'isFavorite': isFavorite
  };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
    json['id'], json['name'], json['category'], json['basePrice'],
    json['imageUrl'], json['isVeg'], json['description'],
    variants: (json['variants'] as List?)?.map((v) => FoodVariant.fromJson(v)).toList() ?? [],
    isFavorite: json['isFavorite'] ?? false
  );
}

class CartItem {
  final FoodItem item;
  final FoodVariant? selectedVariant;
  final int quantity;
  
  CartItem(this.item, this.quantity, {this.selectedVariant});
  
  double get totalPrice => (selectedVariant?.price ?? item.basePrice) * quantity;
  String get displayName => selectedVariant != null ? "${item.name} (${selectedVariant!.name})" : item.name;

  Map<String, dynamic> toJson() => {'item': item.toJson(), 'selectedVariant': selectedVariant?.toJson(), 'quantity': quantity};
  
  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    FoodItem.fromJson(json['item']), json['quantity'], 
    selectedVariant: json['selectedVariant'] != null ? FoodVariant.fromJson(json['selectedVariant']) : null
  );
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final bool isCredit;
  final String method;
  final DateTime date;

  Transaction(this.id, this.title, this.amount, this.isCredit, this.method, this.date);

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'amount': amount, 'isCredit': isCredit, 'method': method, 'date': date.toIso8601String()};
  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(json['id'], json['title'], json['amount'], json['isCredit'], json['method'], DateTime.parse(json['date']));
}

class Order {
  final String id;
  final List<CartItem> items;
  final double total;
  final double discount;
  final DateTime timestamp;
  int? rating;

  Order(this.id, this.items, this.total, this.discount, this.timestamp, {this.rating});

  Map<String, dynamic> toJson() => {'id': id, 'items': items.map((i) => i.toJson()).toList(), 'total': total, 'discount': discount, 'timestamp': timestamp.toIso8601String(), 'rating': rating};
  factory Order.fromJson(Map<String, dynamic> json) => Order(json['id'], (json['items'] as List).map((i) => CartItem.fromJson(i)).toList(), json['total'], json['discount'] ?? 0.0, DateTime.parse(json['timestamp']), rating: json['rating']);
}

// --- MOCK MENU (Detailed Descriptions) ---
final List<FoodItem> fullMenu = [
  // THALIS
  FoodItem("101", "Chole Bhature Thali", "Thali", 120, "🥘", true, "Experience the taste of North India with 2 huge, fluffy Bhature served with spicy, tangy Chole masala. Includes pickle, onions, and a glass of refreshing chaas.", variants: [FoodVariant("Half", 80), FoodVariant("Full", 120)]),
  FoodItem("102", "Rajma Chawal Thali", "Thali", 110, "🍛", true, "Comfort food at its best. Homestyle kidney beans cooked in tomato gravy, served over steaming hot Basmati rice. Comes with roasted papad and mint chutney.", variants: [FoodVariant("Mini", 70), FoodVariant("Full", 110)]),
  FoodItem("103", "Chicken Curry Thali", "Thali", 160, "🍗", false, "A hearty meal featuring tender chicken simmered in a rich aromatic gravy. Served with 2 butter rotis, jeera rice, fresh garden salad, and a sweet gulab jamun.", variants: [FoodVariant("Standard", 160), FoodVariant("Deluxe", 200)]),
  FoodItem("104", "South Indian Thali", "Thali", 100, "🥥", true, "A complete platter: 2 soft Idlis, 1 crispy Medu Vada, Mini Dosa, piping hot Sambar, Coconut Chutney, and Tomato Chutney."),
  FoodItem("105", "Veg Deluxe Thali", "Thali", 150, "🥗", true, "The ultimate veg feast. Paneer Butter Masala, Dal Makhani, 2 Butter Naans, Pulao, Raita, Salad, and a dessert of the day."),

  // MEALS
  FoodItem("201", "Classic Burger", "Meals", 60, "🍔", false, "Flame-grilled chicken patty topped with melted cheddar, fresh lettuce, tomatoes, and our secret Saints sauce on a toasted sesame bun."),
  FoodItem("202", "Veggie Burger", "Meals", 50, "🥬", true, "Crispy mixed vegetable patty with potatoes and peas, topped with creamy mayonnaise and crunchy onions."),
  FoodItem("203", "Cheese Pizza", "Meals", 99, "🍕", true, "Classic Margherita with a rich tomato base and an overload of mozzarella cheese, finished with a sprinkle of oregano.", variants: [FoodVariant("Regular", 99), FoodVariant("Large", 199)]),
  FoodItem("204", "Chicken Pizza", "Meals", 149, "🍖", false, "Loaded with BBQ chicken chunks, onions, paprika, and extra cheese on a thin crust base.", variants: [FoodVariant("Regular", 149), FoodVariant("Large", 249)]),
  FoodItem("205", "Veg Biryani", "Meals", 130, "🍚", true, "Long grain Basmati rice slow-cooked with fresh carrots, beans, cauliflower, and authentic whole spices. Served with Raita."),
  FoodItem("207", "Chicken Wrap", "Meals", 90, "🌯", false, "Spicy grilled chicken strips wrapped in a soft tortilla with crunchy peppers and spicy mayo."),
  FoodItem("209", "Pasta Alfredo", "Meals", 110, "🍝", true, "Penne pasta tossed in a rich, creamy white cheese sauce with sweet corn, broccoli, and black olives."),

  // SNACKS
  FoodItem("301", "Peri Peri Fries", "Snacks", 60, "🍟", true, "Golden crispy french fries generously dusted with spicy Peri-Peri seasoning.", variants: [FoodVariant("Small", 40), FoodVariant("Large", 60)]),
  FoodItem("302", "Veg Sandwich", "Snacks", 45, "🥪", true, "Triple-layer grilled sandwich filled with fresh cucumber, tomato, potato slices, and spicy green chutney."),
  FoodItem("303", "Chicken Nuggets", "Snacks", 90, "🍖", false, "6 pieces of golden, crunchy fried chicken nuggets. Perfect for a quick bite. Served with ketchup."),
  FoodItem("304", "Samosa (2pcs)", "Snacks", 30, "🥟", true, "Traditional triangular pastry filled with spiced mashed potatoes and peas. Served hot with mint chutney."),
  FoodItem("305", "Garlic Bread", "Snacks", 70, "🥖", true, "Oven-baked baguette slices topped with garlic butter and mixed herbs."),

  // DRINKS
  FoodItem("401", "Coca Cola", "Drinks", 25, "🥤", true, "Chilled fizzy cola to refresh your thirst.", variants: [FoodVariant("Can", 25), FoodVariant("Bottle", 40)]),
  FoodItem("402", "Cold Coffee", "Drinks", 60, "🧋", true, "Thick and creamy blended coffee topped with a scoop of vanilla ice cream and chocolate syrup."),
  FoodItem("403", "Mango Lassi", "Drinks", 50, "🥭", true, "Thick, sweet yogurt drink blended with fresh Alphonso mango pulp."),
  FoodItem("405", "Mint Mojito", "Drinks", 70, "🍹", true, "Non-alcoholic refreshing cooler made with fresh mint leaves, lime, sugar, and soda."),
];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SaintsKitchenApp());
}

class SaintsKitchenApp extends StatelessWidget {
  const SaintsKitchenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saints Kitchen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF6200EA),
        scaffoldBackgroundColor: const Color(0xFFF8F9FE),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6200EA), secondary: const Color(0xFFFFD700)),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const SplashScreen(),
    );
  }
}

// --- SCREEN 1: SPLASH (Restored V2.0 Style + App Name) ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), _checkLogin);
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => isLoggedIn ? const MainScreen() : const LoginScreen(),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6200EA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, color: Colors.white, size: 80),
            const SizedBox(height: 20),
            Text("SAINTS KITCHEN", style: GoogleFonts.bebasNeue(fontSize: 40, color: Colors.white, letterSpacing: 3)),
            const SizedBox(height: 5),
            Text("Saints Row III School", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// --- SCREEN 2: LOGIN ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    if (_nameCtrl.text.isEmpty || _idCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('name', _nameCtrl.text);
    await prefs.setString('id', _idCtrl.text);
    if (!prefs.containsKey('wallet')) await prefs.setDouble('wallet', 0.0);
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6200EA), Color(0xFF9900F0)])),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fastfood_rounded, size: 60, color: Color(0xFF6200EA)),
                const SizedBox(height: 20),
                Text("Student Login", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Name", prefixIcon: Icon(Icons.person), border: OutlineInputBorder())),
                const SizedBox(height: 15),
                TextField(controller: _idCtrl, decoration: const InputDecoration(labelText: "Reg No", prefixIcon: Icon(Icons.badge), border: OutlineInputBorder())),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6200EA), foregroundColor: Colors.white),
                  onPressed: _loading ? null : _login,
                  child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("LOGIN"),
                ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- SCREEN 3: MAIN NAV ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0;
  List<CartItem> cart = [];

  void addToCart(FoodItem item, FoodVariant? variant, int qty) {
    setState(() => cart.add(CartItem(item, qty, selectedVariant: variant)));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${item.name} added!"), duration: const Duration(milliseconds: 500)));
  }

  void clearCart() => setState(() => cart.clear());

  @override
  Widget build(BuildContext context) {
    final tabs = [
      MenuPage(onAddToCart: addToCart),
      OrdersPage(currentCart: cart, onClearCart: clearCart),
      const WalletPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _idx, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.restaurant_menu), label: "Menu"),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: "Orders"),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: "Wallet"),
          NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// --- SCREEN 4: MENU (Extended) ---
class MenuPage extends StatefulWidget {
  final Function(FoodItem, FoodVariant?, int) onAddToCart;
  const MenuPage({super.key, required this.onAddToCart});
  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String selectedCat = "Thali";
  String searchQuery = "";
  final categories = ["All", "Thali", "Meals", "Snacks", "Drinks"];

  List<FoodItem> get filteredItems {
    return fullMenu.where((item) {
      final matchesCat = selectedCat == "All" || item.category == selectedCat;
      final matchesSearch = item.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();
  }

  void _showProductDetails(FoodItem item) {
    FoodVariant? selectedVar = item.variants.isNotEmpty ? item.variants.first : null;
    int qty = 1;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(builder: (context, setSheetState) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Center(child: Text(item.imageUrl, style: const TextStyle(fontSize: 80))),
            const SizedBox(height: 20),
            Text(item.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(item.description, style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.5)),
            const SizedBox(height: 20),
            if (item.variants.isNotEmpty) ...[
              const Text("Select Size/Variant:", style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(spacing: 10, children: item.variants.map((v) => ChoiceChip(
                label: Text("${v.name} - ₹${v.price}"),
                selected: selectedVar == v,
                onSelected: (b) => setSheetState(() => selectedVar = v),
                selectedColor: const Color(0xFFFFD700),
              )).toList()),
              const SizedBox(height: 20),
            ],
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("Quantity", style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  IconButton(onPressed: () => qty > 1 ? setSheetState(() => qty--) : null, icon: const Icon(Icons.remove)),
                  Text("$qty", style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => setSheetState(() => qty++), icon: const Icon(Icons.add)),
                ])
              )
            ]),
            const Spacer(),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6200EA), foregroundColor: Colors.white),
              onPressed: () { widget.onAddToCart(item, selectedVar, qty); Navigator.pop(context); },
              child: Text("ADD TO CART - ₹${((selectedVar?.price ?? item.basePrice) * qty).toInt()}"),
            ))
          ],
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(padding: const EdgeInsets.all(20), child: TextField(onChanged: (v) => setState(() => searchQuery = v), decoration: InputDecoration(hintText: "Search dishes...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))))),
          SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: categories.map((cat) => Padding(padding: const EdgeInsets.only(right: 10), child: ChoiceChip(label: Text(cat), selected: selectedCat == cat, onSelected: (b) => setState(() => selectedCat = cat), selectedColor: const Color(0xFF6200EA), labelStyle: TextStyle(color: selectedCat == cat ? Colors.white : Colors.black)))).toList())),
          const SizedBox(height: 10),
          Expanded(child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 15, mainAxisSpacing: 15),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return GestureDetector(
                onTap: () => _showProductDetails(item),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(item.imageUrl, style: const TextStyle(fontSize: 45)),
                    const SizedBox(height: 10),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(item.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))),
                    Text(item.variants.isNotEmpty ? "From ₹${item.variants[0].price}" : "₹${item.basePrice}", style: const TextStyle(color: Colors.grey)),
                  ]),
                ),
              );
            },
          )),
        ],
      ),
    );
  }
}

// --- SCREEN 5: CART & ORDERS (Fixed Animation & Logic) ---
class OrdersPage extends StatefulWidget {
  final List<CartItem> currentCart;
  final VoidCallback onClearCart;
  const OrdersPage({super.key, required this.currentCart, required this.onClearCart});
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Order> orderHistory = [];
  final _couponCtrl = TextEditingController();
  double discount = 0.0;
  bool codeApplied = false;

  @override
  void initState() { super.initState(); _loadHistory(); }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final hList = prefs.getString('order_history');
    if (hList != null) setState(() => orderHistory = (jsonDecode(hList) as List).map((i) => Order.fromJson(i)).toList().reversed.toList());
  }

  void _applyCoupon() {
    if (_couponCtrl.text.toUpperCase() == "SAINTS50") {
      setState(() { discount = 50.0; codeApplied = true; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Coupon Applied! ₹50 OFF")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Coupon"), backgroundColor: Colors.red));
    }
  }

  Future<void> _placeOrder() async {
    if (widget.currentCart.isEmpty) return;
    
    // 1. Calculate Costs
    final prefs = await SharedPreferences.getInstance();
    final double wallet = prefs.getDouble('wallet') ?? 0.0;
    final double originalTotal = widget.currentCart.fold(0, (sum, i) => sum + i.totalPrice);
    final double finalTotal = max(0, originalTotal - discount);

    // 2. Check Balance
    if (wallet < finalTotal) {
      // Check for Auto-Pay
      final bool autoPay = prefs.getBool('autopay_enabled') ?? false;
      final double threshold = prefs.getDouble('autopay_threshold') ?? 100.0;
      final double topUpAmt = prefs.getDouble('autopay_amount') ?? 500.0;
      
      if (autoPay && wallet < threshold) {
         // Auto-Topup Triggered
         final double newWallet = wallet + topUpAmt;
         await prefs.setDouble('wallet', newWallet);
         _logTransaction(topUpAmt, true, "Auto-Topup");
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Auto-Recharged ₹$topUpAmt!")));
         // Recursive call to try payment again with new balance
         _placeOrder(); 
         return;
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Insufficient Balance!"), backgroundColor: Colors.red));
      return;
    }

    // 3. SUCCESS ANIMATION (Dialog)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, double value, child) {
                  return Transform.scale(scale: value, child: const Icon(Icons.check_circle, color: Colors.green, size: 80));
                },
              ),
              const SizedBox(height: 20),
              const Text("Order Confirmed!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2)); // Wait for animation
    if(mounted) Navigator.pop(context); // Close dialog

    // 4. Process Payment (DEDUCT NOW)
    await prefs.setDouble('wallet', wallet - finalTotal);
    _logTransaction(finalTotal, false, "Food Order");

    // 5. Save Order
    final newOrder = Order("SK-${Random().nextInt(9999)}", List.from(widget.currentCart), finalTotal, discount, DateTime.now());
    final hList = prefs.getString('order_history');
    List<Order> history = [];
    if (hList != null) history = (jsonDecode(hList) as List).map((i) => Order.fromJson(i)).toList();
    history.add(newOrder);
    await prefs.setString('order_history', jsonEncode(history.map((e) => e.toJson()).toList()));

    widget.onClearCart();
    setState(() { discount = 0.0; codeApplied = false; _couponCtrl.clear(); });
    _loadHistory();
  }

  Future<void> _logTransaction(double amount, bool isCredit, String title) async {
    final prefs = await SharedPreferences.getInstance();
    final tList = prefs.getString('transactions');
    List<Transaction> transactions = [];
    if (tList != null) transactions = (jsonDecode(tList) as List).map((i) => Transaction.fromJson(i)).toList();
    transactions.insert(0, Transaction("TX-${Random().nextInt(9999)}", title, amount, isCredit, "Wallet", DateTime.now()));
    await prefs.setString('transactions', jsonEncode(transactions.map((e) => e.toJson()).toList()));
  }

  Widget _buildStep(String title, String subtitle, bool isActive, bool isCompleted, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: isCompleted ? Colors.green : (isActive ? Colors.orange : Colors.grey[200]), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          Container(width: 2, height: 40, color: Colors.grey[300]),
        ]),
        const SizedBox(width: 15),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isActive || isCompleted ? Colors.black : Colors.grey)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ])
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text("My Orders"), bottom: const TabBar(tabs: [Tab(text: "Cart"), Tab(text: "Track Orders")])),
        body: TabBarView(
          children: [
            // CART TAB
            widget.currentCart.isEmpty ? const Center(child: Text("Cart Empty")) : Column(children: [
              Expanded(child: ListView.builder(itemCount: widget.currentCart.length, itemBuilder: (c, i) => ListTile(title: Text(widget.currentCart[i].displayName), subtitle: Text("Qty: ${widget.currentCart[i].quantity}"), trailing: Text("₹${widget.currentCart[i].totalPrice}")))),
              Container(padding: const EdgeInsets.all(20), color: Colors.white, child: Column(children: [
                Row(children: [Expanded(child: TextField(controller: _couponCtrl, decoration: const InputDecoration(hintText: "Code: SAINTS50", border: OutlineInputBorder()))), const SizedBox(width: 10), ElevatedButton(onPressed: _applyCoupon, child: const Text("APPLY"))]),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Total"), Text("₹${max(0, widget.currentCart.fold(0.0, (s, i) => s + i.totalPrice) - discount)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6200EA), foregroundColor: Colors.white), onPressed: _placeOrder, child: const Text("PAY & ORDER")))
              ]))
            ]),
            // TRACKING TAB (New UI)
            ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: orderHistory.length,
              itemBuilder: (context, index) {
                final o = orderHistory[index];
                final mins = DateTime.now().difference(o.timestamp).inMinutes;
                bool cooking = mins >= 1;
                bool ready = mins >= 2;

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ExpansionTile(
                    title: Text("Order #${o.id}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(DateFormat('dd MMM, hh:mm a').format(o.timestamp)),
                    children: [
                      Padding(padding: const EdgeInsets.all(20), child: Column(children: [
                        _buildStep("Order Placed", "Your order is received", true, cooking, Icons.receipt),
                        _buildStep("Cooking", "Chef is preparing your meal", cooking, ready, Icons.soup_kitchen),
                        _buildStep("Ready to Pickup", "Scan QR at counter", ready, ready, Icons.check_circle),
                        const SizedBox(height: 10),
                        if (ready) ...[
                          QrImageView(data: o.id, size: 120),
                          const Text("SCAN THIS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ] else const LinearProgressIndicator(),
                        const Divider(),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Paid Amount:"), Text("₹${o.total}", style: const TextStyle(fontWeight: FontWeight.bold))]),
                      ]))
                    ],
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

// --- SCREEN 6: WALLET (Smart Auto-Pay & Config) ---
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});
  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  double wallet = 0.0;
  List<Transaction> transactions = [];
  bool autoPayEnabled = false;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      wallet = prefs.getDouble('wallet') ?? 0.0;
      autoPayEnabled = prefs.getBool('autopay_enabled') ?? false;
      final tList = prefs.getString('transactions');
      if (tList != null) transactions = (jsonDecode(tList) as List).map((i) => Transaction.fromJson(i)).toList();
    });
  }

  void _configureAutoPay() {
    final _threshCtrl = TextEditingController();
    final _amtCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Configure Auto-Pay"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("Automatically top-up wallet when balance is low."),
        const SizedBox(height: 15),
        TextField(controller: _threshCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "If balance below (₹)", border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: _amtCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Add Amount (₹)", border: OutlineInputBorder())),
        const SizedBox(height: 10),
        const DropdownMenu(dropdownMenuEntries: [DropdownMenuEntry(value: "Card", label: "Use Saved Card"), DropdownMenuEntry(value: "UPI", label: "Use Saved UPI")], label: Text("Payment Method")),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
        ElevatedButton(onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('autopay_enabled', true);
          await prefs.setDouble('autopay_threshold', double.tryParse(_threshCtrl.text) ?? 100);
          await prefs.setDouble('autopay_amount', double.tryParse(_amtCtrl.text) ?? 500);
          setState(() => autoPayEnabled = true);
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Auto-Pay Configured!")));
        }, child: const Text("SAVE"))
      ],
    ));
  }

  void _showDepositDialog() {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => const DepositSheet()).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wallet")),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6200EA), Color(0xFF651FFF)]), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("Balance", style: TextStyle(color: Colors.white, fontSize: 18)),
              Text("₹${wallet.toInt()}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ]),
          ),
          ListTile(
            title: const Text("Auto-Topup"),
            subtitle: Text(autoPayEnabled ? "Active" : "Disabled"),
            trailing: Switch(value: autoPayEnabled, onChanged: (v) => v ? _configureAutoPay() : setState(() { autoPayEnabled = false; SharedPreferences.getInstance().then((p) => p.setBool('autopay_enabled', false)); })),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _showDepositDialog, child: const Text("ADD MONEY")))),
          Expanded(child: ListView.builder(itemCount: transactions.length, itemBuilder: (c, i) {
            final t = transactions[i];
            return ListTile(
              leading: Icon(t.isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: t.isCredit ? Colors.green : Colors.red),
              title: Text(t.title), subtitle: Text(DateFormat('dd MMM').format(t.date)),
              trailing: Text("${t.isCredit ? '+' : '-'} ₹${t.amount}", style: TextStyle(color: t.isCredit ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
            );
          }))
        ],
      ),
    );
  }
}

class DepositSheet extends StatefulWidget {
  const DepositSheet({super.key});
  @override
  State<DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<DepositSheet> {
  int _method = 0; 
  final _amountCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _pay() async {
    if (_amountCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    double amt = double.parse(_amountCtrl.text);
    double cur = prefs.getDouble('wallet') ?? 0;
    await prefs.setDouble('wallet', cur + amt);
    
    // Log
    final tList = prefs.getString('transactions');
    List<Transaction> ts = [];
    if (tList != null) ts = (jsonDecode(tList) as List).map((i) => Transaction.fromJson(i)).toList();
    ts.insert(0, Transaction("TX-${Random().nextInt(9999)}", "Deposit", amt, true, _method == 0 ? "Card" : "UPI", DateTime.now()));
    await prefs.setString('transactions', jsonEncode(ts.map((e) => e.toJson()).toList()));
    
    if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Money Added!"))); }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("Add Money", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(children: [
          ChoiceChip(label: const Text("Card"), selected: _method == 0, onSelected: (b) => setState(() => _method = 0)),
          const SizedBox(width: 10),
          ChoiceChip(label: const Text("UPI"), selected: _method == 1, onSelected: (b) => setState(() => _method = 1)),
        ]),
        const SizedBox(height: 15),
        TextField(controller: _amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount (₹)", border: OutlineInputBorder())),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _pay, child: _loading ? const CircularProgressIndicator() : const Text("PAY NOW"))),
        const SizedBox(height: 20),
      ]),
    );
  }
}

// --- SCREEN 7: PROFILE (Restored Support) ---
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "";
  String id = "";
  int eggTaps = 0;

  @override
  void initState() { super.initState(); _loadData(); }
  Future<void> _loadData() async { final prefs = await SharedPreferences.getInstance(); setState(() { name = prefs.getString('name') ?? ""; id = prefs.getString('id') ?? ""; }); }

  void _showSupport() {
    showModalBottomSheet(context: context, builder: (_) => Container(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("Saints Support", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ListTile(leading: const Icon(Icons.warning), title: const Text("Raise a Complaint"), onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ticket #SR-${Random().nextInt(999)} Created.")));
        }),
        ListTile(leading: const Icon(Icons.chat), title: const Text("Chat with Admin"), onTap: () {}),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Center(
        child: Column(children: [
          const SizedBox(height: 30),
          GestureDetector(
            onTap: () {
              setState(() => eggTaps++);
              if (eggTaps == 5) {
                showDialog(context: context, builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF2D2D2D),
                  title: const Text("⚡ FANTASTIC 6 ⚡", style: TextStyle(color: Colors.white)),
                  content: const Text("Mohammed Shameem J\nAryaman Yadav\nShivam Chandra\nKrishna Santhanam", style: TextStyle(color: Colors.white70)),
                ));
                eggTaps = 0;
              }
            },
            child: const CircleAvatar(radius: 60, backgroundColor: Color(0xFF6200EA), child: Icon(Icons.person, size: 60, color: Colors.white)),
          ),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text("Reg: $id", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          ListTile(leading: const Icon(Icons.headset_mic), title: const Text("Help & Support"), onTap: _showSupport, trailing: const Icon(Icons.chevron_right)),
          ListTile(leading: const Icon(Icons.info), title: const Text("About App"), trailing: const Icon(Icons.chevron_right)),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Logout"), onTap: () async {
            final prefs = await SharedPreferences.getInstance(); await prefs.clear();
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
          })
        ]),
      ),
    );
  }
}
