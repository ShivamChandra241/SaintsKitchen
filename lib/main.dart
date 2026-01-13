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

// --- RESTORED MOCK MENU (40+ ITEMS) ---
final List<FoodItem> fullMenu = [
  // THALIS
  FoodItem("101", "Chole Bhature Thali", "Thali", 120, "🥘", true, "2 Fluffy Bhature, Spicy Chole, Pickle, Salad & Lassi.", variants: [FoodVariant("Half", 80), FoodVariant("Full", 120)]),
  FoodItem("102", "Rajma Chawal Thali", "Thali", 110, "🍛", true, "Home-style Rajma, Basmati Rice, Raita & Papad.", variants: [FoodVariant("Mini", 70), FoodVariant("Full", 110)]),
  FoodItem("103", "Chicken Curry Thali", "Thali", 160, "🍗", false, "Spicy Chicken Curry, 2 Rotis, Jeera Rice, Salad.", variants: [FoodVariant("Standard", 160), FoodVariant("Deluxe", 200)]),
  FoodItem("104", "South Indian Thali", "Thali", 100, "🥥", true, "Idli, Vada, Mini Dosa, Sambar, Coconut & Tomato Chutney."),
  FoodItem("105", "Veg Deluxe Thali", "Thali", 150, "🥗", true, "Paneer Butter Masala, Dal Makhani, 2 Naan, Rice & Sweet."),
  FoodItem("106", "Fish Curry Thali", "Thali", 180, "🐟", false, "Coastal style Fish Curry, Steamed Rice, Sol Kadhi."),
  FoodItem("107", "Egg Curry Thali", "Thali", 130, "🥚", false, "2 Egg Curry, 3 Chapatis, Rice, Salad."),
  FoodItem("108", "Dal Baati Churma", "Thali", 140, "🥣", true, "Traditional Rajasthani Dal Baati with sweet Churma."),
  
  // MEALS
  FoodItem("201", "Classic Burger", "Meals", 60, "🍔", false, "Grilled patty, lettuce, tomato & saints sauce."),
  FoodItem("202", "Veggie Burger", "Meals", 50, "🥬", true, "Crispy potato & peas patty with mayo."),
  FoodItem("203", "Cheese Pizza", "Meals", 99, "🍕", true, "Mozzarella cheese burst with basil.", variants: [FoodVariant("Regular", 99), FoodVariant("Large", 199)]),
  FoodItem("204", "Chicken Pizza", "Meals", 149, "🍖", false, "BBQ Chicken chunks, onions and paprika.", variants: [FoodVariant("Regular", 149), FoodVariant("Large", 249)]),
  FoodItem("205", "Veg Biryani", "Meals", 130, "🍚", true, "Aromatic basmati rice cooked with fresh garden veggies."),
  FoodItem("206", "Chicken Biryani", "Meals", 180, "🍗", false, "Hyderabadi style dum biryani with raita."),
  FoodItem("207", "Chicken Wrap", "Meals", 90, "🌯", false, "Spicy chicken strips in a soft tortilla wrap."),
  FoodItem("208", "Paneer Tikka Roll", "Meals", 85, "🥙", true, "Char-grilled paneer cubes wrapped in roomali roti."),
  FoodItem("209", "Pasta Alfredo", "Meals", 110, "🍝", true, "White sauce penne pasta with corn and olives."),
  FoodItem("210", "Pasta Arrabbiata", "Meals", 110, "🍅", true, "Red sauce spicy pasta with basil."),
  FoodItem("211", "Fried Rice", "Meals", 90, "🥡", true, "Indo-Chinese style veg fried rice."),
  FoodItem("212", "Hakka Noodles", "Meals", 90, "🥢", true, "Stir-fried noodles with crunchy vegetables."),

  // SNACKS
  FoodItem("301", "Peri Peri Fries", "Snacks", 60, "🍟", true, "Crispy fries tossed in spicy peri peri mix.", variants: [FoodVariant("Small", 40), FoodVariant("Large", 60)]),
  FoodItem("302", "Veg Sandwich", "Snacks", 45, "🥪", true, "Grilled sandwich with cucumber, tomato & chutney."),
  FoodItem("303", "Chicken Nuggets", "Snacks", 90, "🍖", false, "6 pieces of golden fried chicken nuggets with dip."),
  FoodItem("304", "Samosa (2pcs)", "Snacks", 30, "🥟", true, "Hot potato stuffed samosas with mint chutney."),
  FoodItem("305", "Garlic Bread", "Snacks", 70, "🥖", true, "Toasted baguette with garlic butter and herbs."),
  FoodItem("306", "Vada Pav", "Snacks", 25, "🥔", true, "Mumbai style spicy potato slider."),
  FoodItem("307", "Chicken Popcorn", "Snacks", 100, "🍿", false, "Bite sized crunchy fried chicken."),
  FoodItem("308", "Paneer 65", "Snacks", 110, "🌶️", true, "Spicy deep fried paneer cubes."),
  FoodItem("309", "Nachos with Salsa", "Snacks", 80, "🌮", true, "Crispy tortilla chips with tangy salsa dip."),
  FoodItem("310", "Spring Rolls", "Snacks", 70, "🌯", true, "Crispy fried rolls stuffed with veggies."),

  // DRINKS
  FoodItem("401", "Coca Cola", "Drinks", 25, "🥤", true, "Chilled fizzy cola.", variants: [FoodVariant("Can", 25), FoodVariant("Bottle", 40)]),
  FoodItem("402", "Cold Coffee", "Drinks", 60, "🧋", true, "Creamy blended coffee with ice cream."),
  FoodItem("403", "Mango Lassi", "Drinks", 50, "🥭", true, "Thick yogurt drink with fresh mango pulp."),
  FoodItem("404", "Masala Chai", "Drinks", 20, "☕", true, "Hot tea infused with cardamom and ginger."),
  FoodItem("405", "Mint Mojito", "Drinks", 70, "🍹", true, "Refreshing lime and mint virgin mojito."),
  FoodItem("406", "Orange Juice", "Drinks", 60, "🍊", true, "Freshly squeezed orange juice."),
  FoodItem("407", "Chocolate Milkshake", "Drinks", 80, "🍫", true, "Thick chocolate shake with brownie crumbs."),
  FoodItem("408", "Lemon Iced Tea", "Drinks", 50, "🍋", true, "Chilled tea with a hint of lemon."),
  FoodItem("409", "Water Bottle", "Drinks", 20, "💧", true, "1 Litre mineral water bottle."),
  
  // DESSERTS
  FoodItem("501", "Choco Lava Cake", "Dessert", 80, "🍰", true, "Warm chocolate cake with a gooesy center."),
  FoodItem("502", "Gulab Jamun (2pcs)", "Dessert", 40, "🍯", true, "Fried dough balls soaked in sugar syrup."),
  FoodItem("503", "Ice Cream Scoop", "Dessert", 50, "🍦", true, "Vanilla, Strawberry or Chocolate scoop."),
  FoodItem("504", "Brownie with Ice Cream", "Dessert", 100, "🍮", true, "Walnut brownie topped with vanilla ice cream."),
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

// --- SCREEN 1: SPLASH (Upgraded Details) ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), _checkLogin);
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF6200EA), Color(0xFF3700B3)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)]),
                child: const Icon(Icons.restaurant_menu, color: Color(0xFF6200EA), size: 60),
              ),
              const SizedBox(height: 20),
              Text("SAINTS KITCHEN", style: GoogleFonts.bebasNeue(fontSize: 42, color: Colors.white, letterSpacing: 3)),
              const SizedBox(height: 5),
              Text("Saints Row III School", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 50),
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 10),
              const Text("Loading Menu...", style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 50),
              const Text("v7.0.0 • Made with ❤️ by Fantastic 6", style: TextStyle(color: Colors.white30, fontSize: 10)),
            ],
          ),
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

// --- SCREEN 4: MENU ---
class MenuPage extends StatefulWidget {
  final Function(FoodItem, FoodVariant?, int) onAddToCart;
  const MenuPage({super.key, required this.onAddToCart});
  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String selectedCat = "Thali";
  String searchQuery = "";
  final categories = ["All", "Thali", "Meals", "Snacks", "Drinks", "Dessert"];

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
          Padding(padding: const EdgeInsets.all(20), child: TextField(onChanged: (v) => setState(() => searchQuery = v), decoration: InputDecoration(hintText: "Search 40+ items...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))))),
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

// --- SCREEN 5: ORDERS ---
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
    
    final prefs = await SharedPreferences.getInstance();
    final double wallet = prefs.getDouble('wallet') ?? 0.0;
    final double originalTotal = widget.currentCart.fold(0, (sum, i) => sum + i.totalPrice);
    final double finalTotal = max(0, originalTotal - discount);

    if (wallet < finalTotal) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Insufficient Balance!"), backgroundColor: Colors.red));
      return;
    }

    // CHECKOUT ANIMATION
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, double value, child) => Transform.scale(scale: value, child: const Icon(Icons.check_circle, color: Colors.green, size: 80)),
            ),
            const SizedBox(height: 20),
            const Text("Order Confirmed!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ]),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    if(mounted) Navigator.pop(context);

    // DEDUCT WALLET & SAVE
    await prefs.setDouble('wallet', wallet - finalTotal);
    
    // LOG TRANSACTION
    final tList = prefs.getString('transactions');
    List<Transaction> transactions = [];
    if (tList != null) transactions = (jsonDecode(tList) as List).map((i) => Transaction.fromJson(i)).toList();
    transactions.insert(0, Transaction("ORD-${Random().nextInt(9999)}", "Food Order", finalTotal, false, "Wallet", DateTime.now()));
    await prefs.setString('transactions', jsonEncode(transactions.map((e) => e.toJson()).toList()));

    // SAVE ORDER
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

  Widget _buildStep(String title, bool isActive, bool isCompleted, IconData icon) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Icon(icon, color: isCompleted ? Colors.green : (isActive ? Colors.orange : Colors.grey)),
        Container(width: 2, height: 30, color: Colors.grey[300]),
      ]),
      const SizedBox(width: 15),
      Text(title, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text("My Orders"), bottom: const TabBar(tabs: [Tab(text: "Cart"), Tab(text: "Track Orders")])),
        body: TabBarView(
          children: [
            // CART
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
            // TRACKING
            ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: orderHistory.length,
              itemBuilder: (context, index) {
                final o = orderHistory[index];
                final mins = DateTime.now().difference(o.timestamp).inMinutes;
                bool cooking = mins >= 1;
                bool ready = mins >= 2;

                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: ExpansionTile(
                    title: Text("Order #${o.id}"),
                    subtitle: Text(DateFormat('dd MMM, hh:mm a').format(o.timestamp)),
                    children: [
                      Padding(padding: const EdgeInsets.all(20), child: Column(children: [
                        _buildStep("Order Placed", true, cooking, Icons.receipt),
                        _buildStep("Cooking", cooking, ready, Icons.soup_kitchen),
                        _buildStep("Ready to Pickup", ready, ready, Icons.check_circle),
                        const SizedBox(height: 10),
                        if (ready) ...[QrImageView(data: o.id, size: 100), const Text("SCAN AT COUNTER", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))],
                        if (!ready) const LinearProgressIndicator(),
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

// --- SCREEN 6: WALLET (RESTORED DETAILS) ---
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});
  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  double wallet = 0.0;
  List<Transaction> transactions = [];

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      wallet = prefs.getDouble('wallet') ?? 0.0;
      final tList = prefs.getString('transactions');
      if (tList != null) transactions = (jsonDecode(tList) as List).map((i) => Transaction.fromJson(i)).toList();
    });
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
  int _method = 0; // 0=Card, 1=UPI
  final _amountCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
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
        
        // RESTORED CARD DETAILS
        if (_method == 0) ...[
          TextField(controller: _cardCtrl, keyboardType: TextInputType.number, maxLength: 16, decoration: const InputDecoration(labelText: "Card Number", counterText: "", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: _expiryCtrl, decoration: const InputDecoration(labelText: "MM/YY", border: OutlineInputBorder()))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _cvvCtrl, obscureText: true, maxLength: 3, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "CVV", counterText: "", border: OutlineInputBorder()))),
          ]),
          const SizedBox(height: 10),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Cardholder Name", border: OutlineInputBorder())),
        ],

        // RESTORED UPI ID
        if (_method == 1) TextField(controller: _upiCtrl, decoration: const InputDecoration(labelText: "UPI ID (e.g. name@upi)", border: OutlineInputBorder())),

        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _pay, child: _loading ? const CircularProgressIndicator() : const Text("PAY NOW"))),
        const SizedBox(height: 20),
      ]),
    );
  }
}

// --- SCREEN 7: PROFILE (New Options + About Text) ---
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

  void _showAbout() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text("About Us"),
      content: const Text("Developed by Team Fantastic 6 to tackle the problem with overcrowding in the canteen during lunch. This app helps in reducing crowd by using online ordering and payment."),
    ));
  }

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
                  content: const Text("1. Mohammed Shameem J (RA2411028020104)\n2. Aryaman Yadav (RA2411028020086)\n3. Shivam Chandra (RA2311028020049)\n4. Krishna Santhanam (RA2411028020136)", style: TextStyle(color: Colors.white70)),
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
          ListTile(leading: const Icon(Icons.notifications), title: const Text("Notifications"), onTap: () {}),
          ListTile(leading: const Icon(Icons.location_on), title: const Text("Saved Addresses"), onTap: () {}),
          ListTile(leading: const Icon(Icons.settings), title: const Text("App Settings"), onTap: () {}),
          const Divider(),
          ListTile(leading: const Icon(Icons.headset_mic), title: const Text("Help & Support"), onTap: _showSupport),
          ListTile(leading: const Icon(Icons.info), title: const Text("About Us"), onTap: _showAbout),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Logout"), onTap: () async {
            final prefs = await SharedPreferences.getInstance(); await prefs.clear();
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
          })
        ]),
      ),
    );
  }
}
