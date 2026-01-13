import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';

// --- DATA MODELS ---

class FoodVariant {
  final String name; // e.g., "Half", "Full", "Small", "Large"
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
  final String imageUrl; // URL or Emoji
  final bool isVeg;
  final String description;
  final List<FoodVariant> variants; // Optional variants
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

  Map<String, dynamic> toJson() => {
    'item': item.toJson(), 'selectedVariant': selectedVariant?.toJson(), 'quantity': quantity
  };
  
  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    FoodItem.fromJson(json['item']), json['quantity'], 
    selectedVariant: json['selectedVariant'] != null ? FoodVariant.fromJson(json['selectedVariant']) : null
  );
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final bool isCredit; // true = added money, false = spent
  final String method; // "UPI", "Card", "Wallet"
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
  int? rating; // 1-5 stars

  Order(this.id, this.items, this.total, this.discount, this.timestamp, {this.rating});

  Map<String, dynamic> toJson() => {'id': id, 'items': items.map((i) => i.toJson()).toList(), 'total': total, 'discount': discount, 'timestamp': timestamp.toIso8601String(), 'rating': rating};
  factory Order.fromJson(Map<String, dynamic> json) => Order(json['id'], (json['items'] as List).map((i) => CartItem.fromJson(i)).toList(), json['total'], json['discount'] ?? 0.0, DateTime.parse(json['timestamp']), rating: json['rating']);
}

// --- MOCK MENU (20+ Items with Thalis) ---
final List<FoodItem> fullMenu = [
  // THALIS (New Category)
  FoodItem("101", "Chole Bhature Thali", "Thali", 120, "🥘", true, "2 Bhature, Spicy Chole, Pickle, Salad & Lassi.", variants: [FoodVariant("Half", 80), FoodVariant("Full", 120)]),
  FoodItem("102", "Rajma Chawal Thali", "Thali", 110, "🍛", true, "Home-style Rajma, Basmati Rice, Raita & Papad.", variants: [FoodVariant("Mini", 70), FoodVariant("Full", 110)]),
  FoodItem("103", "Chicken Curry Thali", "Thali", 160, "🍗", false, "Chicken Curry, 2 Rotis, Rice, Salad & Gulab Jamun.", variants: [FoodVariant("Standard", 160), FoodVariant("Deluxe", 200)]),
  FoodItem("104", "South Indian Thali", "Thali", 100, "🥥", true, "Idli, Vada, Mini Dosa, Sambar & 2 Chutneys."),
  FoodItem("105", "Veg Deluxe Thali", "Thali", 150, "🥗", true, "Paneer Butter Masala, Dal Makhani, Naan & Rice."),

  // MEALS
  FoodItem("201", "Classic Burger", "Meals", 60, "🍔", false, "Grilled patty, lettuce, tomato & saints sauce."),
  FoodItem("202", "Cheese Pizza", "Meals", 99, "🍕", true, "Mozzarella cheese burst with basil.", variants: [FoodVariant("Regular", 99), FoodVariant("Large", 199)]),
  FoodItem("203", "Veg Biryani", "Meals", 130, "🍚", true, "Aromatic rice cooked with fresh veggies."),
  FoodItem("204", "Chicken Wrap", "Meals", 90, "🌯", false, "Spicy chicken strips in a soft tortilla."),
  FoodItem("205", "Paneer Tikka Roll", "Meals", 85, "🥙", true, "Char-grilled paneer cubes in roomali roti."),
  FoodItem("206", "Pasta Alfredo", "Meals", 110, "🍝", true, "White sauce pasta with corn and olives."),

  // SNACKS
  FoodItem("301", "Peri Peri Fries", "Snacks", 60, "🍟", true, "Crispy fries tossed in spicy peri peri mix.", variants: [FoodVariant("Small", 40), FoodVariant("Large", 60)]),
  FoodItem("302", "Veg Sandwich", "Snacks", 45, "🥪", true, "Grilled sandwich with cucumber & tomato."),
  FoodItem("303", "Chicken Nuggets", "Snacks", 90, "🍖", false, "6 pieces of golden fried chicken nuggets."),
  FoodItem("304", "Samosa Chaat", "Snacks", 50, "🥟", true, "Crushed samosa with chutney and yogurt."),
  FoodItem("305", "Garlic Bread", "Snacks", 70, "🥖", true, "Toasted baguette with garlic butter."),

  // DRINKS
  FoodItem("401", "Coca Cola", "Drinks", 25, "🥤", true, "Chilled fizzy cola.", variants: [FoodVariant("Can", 25), FoodVariant("Bottle", 40)]),
  FoodItem("402", "Cold Coffee", "Drinks", 60, "🧋", true, "Blended coffee with ice cream."),
  FoodItem("403", "Mango Lassi", "Drinks", 50, "🥭", true, "Thick yogurt drink with mango pulp."),
  FoodItem("404", "Masala Chai", "Drinks", 20, "☕", true, "Hot tea infused with cardamom."),
  FoodItem("405", "Mint Mojito", "Drinks", 70, "🍹", true, "Refreshing lime and mint cooler."),
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

// --- SCREEN 1: SPLASH ---
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
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => isLoggedIn ? const MainScreen() : const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6200EA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)]),
              child: const Icon(Icons.restaurant_menu, size: 60, color: Color(0xFF6200EA)),
            ),
            const SizedBox(height: 20),
            Text("SAINTS KITCHEN", style: GoogleFonts.bebasNeue(fontSize: 48, color: Colors.white, letterSpacing: 2)),
            const SizedBox(height: 5),
            const Text("Saints Row III School", style: TextStyle(color: Colors.white70, fontSize: 16)),
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
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6200EA), Color(0xFF3700B3)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Center(
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school, size: 50, color: Color(0xFF6200EA)),
                  const SizedBox(height: 10),
                  Text("Student Login", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person), border: OutlineInputBorder())),
                  const SizedBox(height: 15),
                  TextField(controller: _idCtrl, decoration: const InputDecoration(labelText: "Reg Number", prefixIcon: Icon(Icons.badge), border: OutlineInputBorder())),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6200EA), foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
                    onPressed: _loading ? null : _login,
                    child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("ENTER KITCHEN"),
                  ))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- SCREEN 3: MAIN NAVIGATION ---
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${item.name} added!"), behavior: SnackBarBehavior.floating, width: 200));
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
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: GNav(
            selectedIndex: _idx,
            onTabChange: (i) => setState(() => _idx = i),
            activeColor: Colors.white,
            tabBackgroundColor: const Color(0xFF6200EA),
            padding: const EdgeInsets.all(12),
            gap: 8,
            tabs: const [
              GButton(icon: Icons.restaurant_menu, text: 'Menu'),
              GButton(icon: Icons.shopping_bag, text: 'Cart'),
              GButton(icon: Icons.account_balance_wallet, text: 'Wallet'),
              GButton(icon: Icons.person, text: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

// Simple Custom Nav Widget for "GNav" style without external package dependency
class GNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChange;
  final List<GButton> tabs;
  final Color activeColor, tabBackgroundColor;
  final double gap;
  final EdgeInsets padding;

  const GNav({super.key, required this.selectedIndex, required this.onTabChange, required this.tabs, required this.activeColor, required this.tabBackgroundColor, required this.gap, required this.padding});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(tabs.length, (index) {
        final isActive = index == selectedIndex;
        return GestureDetector(
          onTap: () => onTabChange(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: padding,
            decoration: BoxDecoration(color: isActive ? tabBackgroundColor : Colors.transparent, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Icon(tabs[index].icon, color: isActive ? activeColor : Colors.grey),
              if (isActive) Padding(padding: EdgeInsets.only(left: gap), child: Text(tabs[index].text, style: TextStyle(color: activeColor, fontWeight: FontWeight.bold)))
            ]),
          ),
        );
      }),
    );
  }
}
class GButton { final IconData icon; final String text; const GButton({required this.icon, required this.text}); }


// --- SCREEN 4: MENU ---
class MenuPage extends StatefulWidget {
  final Function(FoodItem, FoodVariant?, int) onAddToCart;
  const MenuPage({super.key, required this.onAddToCart});
  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String selectedCat = "Thali"; // Default to Thali
  String searchQuery = "";
  final categories = ["All", "Thali", "Meals", "Drinks", "Snacks"];

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
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
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
              const SizedBox(height: 5),
              Text(item.description, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 20),
              if (item.variants.isNotEmpty) ...[
                const Text("Select Option", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: item.variants.map((v) => ChoiceChip(
                    label: Text("${v.name} - ₹${v.price}"),
                    selected: selectedVar == v,
                    onSelected: (b) => setSheetState(() => selectedVar = v),
                    selectedColor: const Color(0xFFFFD700),
                  )).toList(),
                ),
                const SizedBox(height: 20),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Quantity", style: TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        IconButton(onPressed: () => qty > 1 ? setSheetState(() => qty--) : null, icon: const Icon(Icons.remove)),
                        Text("$qty", style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(onPressed: () => setSheetState(() => qty++), icon: const Icon(Icons.add)),
                      ],
                    ),
                  )
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6200EA), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: () { widget.onAddToCart(item, selectedVar, qty); Navigator.pop(context); },
                  child: Text("ADD ₹${((selectedVar?.price ?? item.basePrice) * qty).toInt()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("Saints Row III School", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text("Hungry?", style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF2D2D2D))),
                  ]),
                ),
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]), child: const Icon(Icons.notifications_none)),
              ],
            ),
          ),
          // Search & Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(hintText: "Search thali, snacks...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
            ),
          ),
          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: categories.map((cat) => Padding(padding: const EdgeInsets.only(right: 10), child: ChoiceChip(label: Text(cat), selected: selectedCat == cat, onSelected: (b) => setState(() => selectedCat = cat), selectedColor: const Color(0xFF6200EA), labelStyle: TextStyle(color: selectedCat == cat ? Colors.white : Colors.black)))).toList()),
          ),
          const SizedBox(height: 10),
          // Food Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 15, mainAxisSpacing: 15),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return GestureDetector(
                  onTap: () => _showProductDetails(item),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Center(child: Hero(tag: item.id, child: Text(item.imageUrl, style: const TextStyle(fontSize: 50))))),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(item.variants.isNotEmpty ? "From ₹${item.variants[0].price}" : "₹${item.basePrice}", style: const TextStyle(color: Color(0xFF6200EA), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Row(children: [
                              Icon(Icons.circle, size: 10, color: item.isVeg ? Colors.green : Colors.red),
                              const SizedBox(width: 5),
                              Text(item.category, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ])
                          ]),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- SCREEN 5: CART & ORDERS ---
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
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final hList = prefs.getString('order_history');
    if (hList != null) {
      setState(() => orderHistory = (jsonDecode(hList) as List).map((i) => Order.fromJson(i)).toList().reversed.toList());
    }
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
    final double subtotal = widget.currentCart.fold(0, (sum, i) => sum + i.totalPrice);
    final double finalTotal = max(0, subtotal - discount);

    if (wallet < finalTotal) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Insufficient Balance! Top-up Wallet.")));
      return;
    }

    // Process
    await prefs.setDouble('wallet', wallet - finalTotal);
    
    // Log Transaction
    final tList = prefs.getString('transactions');
    List<Transaction> transactions = [];
    if (tList != null) transactions = (jsonDecode(tList) as List).map((i) => Transaction.fromJson(i)).toList();
    transactions.insert(0, Transaction("ORD-${Random().nextInt(9999)}", "Food Order", finalTotal, false, "Wallet", DateTime.now()));
    await prefs.setString('transactions', jsonEncode(transactions.map((e) => e.toJson()).toList()));

    // Save Order
    final newOrder = Order("SK-${Random().nextInt(9999)}", List.from(widget.currentCart), finalTotal, discount, DateTime.now());
    final hList = prefs.getString('order_history');
    List<Order> history = [];
    if (hList != null) history = (jsonDecode(hList) as List).map((i) => Order.fromJson(i)).toList();
    history.add(newOrder);
    await prefs.setString('order_history', jsonEncode(history.map((e) => e.toJson()).toList()));

    widget.onClearCart();
    setState(() { discount = 0.0; codeApplied = false; _couponCtrl.clear(); });
    _loadHistory();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Placed Successfully!")));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Orders"),
          bottom: const TabBar(labelColor: Color(0xFF6200EA), indicatorColor: Color(0xFF6200EA), tabs: [Tab(text: "Current Cart"), Tab(text: "Track Orders")]),
        ),
        body: TabBarView(
          children: [
            // CART TAB
            widget.currentCart.isEmpty 
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]), const SizedBox(height: 10), const Text("Your cart is empty")])) 
            : Column(
              children: [
                Expanded(child: ListView.builder(itemCount: widget.currentCart.length, itemBuilder: (c, i) {
                  final item = widget.currentCart[i];
                  return ListTile(
                    leading: Text(item.item.imageUrl, style: const TextStyle(fontSize: 30)),
                    title: Text(item.displayName),
                    subtitle: Text("Qty: ${item.quantity}"),
                    trailing: Text("₹${item.totalPrice}"),
                  );
                })),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]),
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: TextField(controller: _couponCtrl, decoration: const InputDecoration(hintText: "Code: SAINTS50", prefixIcon: Icon(Icons.discount), border: OutlineInputBorder()))),
                      const SizedBox(width: 10),
                      ElevatedButton(onPressed: _applyCoupon, child: const Text("APPLY"))
                    ]),
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Subtotal"), Text("₹${widget.currentCart.fold(0.0, (s, i) => s + i.totalPrice)}")]),
                    if (codeApplied) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Discount", style: TextStyle(color: Colors.green)), Text("- ₹$discount", style: const TextStyle(color: Colors.green))]),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Total", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text("₹${max(0, widget.currentCart.fold(0.0, (s, i) => s + i.totalPrice) - discount)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF6200EA)))]),
                    const SizedBox(height: 15),
                    SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6200EA), foregroundColor: Colors.white), onPressed: _placeOrder, child: const Text("PAY & ORDER")))
                  ]),
                )
              ],
            ),
            // HISTORY TAB
            ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: orderHistory.length,
              itemBuilder: (context, index) {
                final o = orderHistory[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ExpansionTile(
                    title: Text("Order #${o.id}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(DateFormat('dd MMM, hh:mm a').format(o.timestamp)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          ...o.items.map((i) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("${i.quantity}x ${i.displayName}"), Text("₹${i.totalPrice}")])).toList(),
                          const Divider(),
                          Center(child: QrImageView(data: o.id, size: 100)),
                          const SizedBox(height: 5),
                          const Center(child: Text("Scan at Counter", style: TextStyle(fontSize: 12, color: Colors.grey))),
                          const Divider(),
                          const Text("Rate Food:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (star) => IconButton(icon: Icon(Icons.star, color: (o.rating ?? 0) > star ? Colors.orange : Colors.grey[300]), onPressed: () {
                            // Mock Rating (Visual Only)
                          })))
                        ]),
                      )
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

// --- SCREEN 6: WALLET & TRANSACTIONS ---
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});
  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  double wallet = 0.0;
  List<Transaction> transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final tList = prefs.getString('transactions');
    setState(() {
      wallet = prefs.getDouble('wallet') ?? 0.0;
      if (tList != null) transactions = (jsonDecode(tList) as List).map((i) => Transaction.fromJson(i)).toList();
    });
  }

  void _showDepositDialog() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const DepositSheet(),
    ).then((_) => _loadData());
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
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6200EA), Color(0xFF651FFF)]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Saints Balance", style: TextStyle(color: Colors.white70)), Text("My Cash", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))]),
                Text("₹${wallet.toInt()}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white), onPressed: _showDepositDialog, icon: const Icon(Icons.add), label: const Text("ADD MONEY")),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(padding: EdgeInsets.only(left: 20), child: Align(alignment: Alignment.centerLeft, child: Text("Transaction History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)))),
          Expanded(
            child: transactions.isEmpty 
            ? const Center(child: Text("No transactions yet.")) 
            : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final t = transactions[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: t.isCredit ? Colors.green[50] : Colors.red[50], child: Icon(t.isCredit ? Icons.south_west : Icons.north_east, color: t.isCredit ? Colors.green : Colors.red)),
                    title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${t.method} • ${DateFormat('dd MMM').format(t.date)}"),
                    trailing: Text("${t.isCredit ? '+' : '-'} ₹${t.amount.toInt()}", style: TextStyle(color: t.isCredit ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- DEPOSIT SHEET ---
class DepositSheet extends StatefulWidget {
  const DepositSheet({super.key});
  @override
  State<DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<DepositSheet> {
  int _method = 0; // 0:Card, 1:UPI, 2:NetBanking
  final _amountCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _pay() async {
    if (_amountCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2)); // Mock Delay
    
    final double amt = double.tryParse(_amountCtrl.text) ?? 0;
    final prefs = await SharedPreferences.getInstance();
    final double cur = prefs.getDouble('wallet') ?? 0;
    await prefs.setDouble('wallet', cur + amt);

    // Log
    final tList = prefs.getString('transactions');
    List<Transaction> ts = [];
    if (tList != null) ts = (jsonDecode(tList) as List).map((i) => Transaction.fromJson(i)).toList();
    ts.insert(0, Transaction("TX-${Random().nextInt(9999)}", _method == 0 ? "Card Deposit" : (_method == 1 ? "UPI Deposit" : "Bank Transfer"), amt, true, _method == 0 ? "Card" : (_method == 1 ? "UPI" : "NetBank"), DateTime.now()));
    await prefs.setString('transactions', jsonEncode(ts.map((e) => e.toJson()).toList()));

    if(mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Money Added!"))); }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Add Money", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Row(children: [
          ChoiceChip(label: const Text("Card"), selected: _method == 0, onSelected: (b) => setState(() => _method = 0)),
          const SizedBox(width: 10),
          ChoiceChip(label: const Text("UPI"), selected: _method == 1, onSelected: (b) => setState(() => _method = 1)),
          const SizedBox(width: 10),
          ChoiceChip(label: const Text("Bank"), selected: _method == 2, onSelected: (b) => setState(() => _method = 2)),
        ]),
        const SizedBox(height: 20),
        TextField(controller: _amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount (₹)", prefixIcon: Icon(Icons.currency_rupee), border: OutlineInputBorder())),
        const SizedBox(height: 15),
        if (_method != 2) TextField(controller: _detailCtrl, decoration: InputDecoration(labelText: _method == 0 ? "Card Number" : "UPI ID", prefixIcon: Icon(_method == 0 ? Icons.credit_card : Icons.alternate_email), border: const OutlineInputBorder())),
        if (_method == 2) DropdownButtonFormField(items: const [DropdownMenuItem(value: "SBI", child: Text("SBI")), DropdownMenuItem(value: "HDFC", child: Text("HDFC"))], onChanged: (v){}, decoration: const InputDecoration(labelText: "Select Bank", border: OutlineInputBorder())),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6200EA), foregroundColor: Colors.white), onPressed: _loading ? null : _pay, child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("PROCEED TO PAY"))),
        const SizedBox(height: 20),
      ]),
    );
  }
}

// --- SCREEN 7: PROFILE & SUPPORT ---
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
        ListTile(leading: const Icon(Icons.question_answer), title: const Text("FAQ: Refund Policy"), subtitle: const Text("Money refunds to wallet in 24hrs.")),
        ListTile(leading: const Icon(Icons.warning), title: const Text("Raise Ticket"), onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ticket #SR-${Random().nextInt(999)} Created. Admin will contact you.")));
        }),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile"), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                setState(() => eggTaps++);
                if(eggTaps == 5) {
                  showDialog(context: context, builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF2D2D2D),
                    title: const Text("⚡ TEAM FANTASTIC 6 ⚡", style: TextStyle(color: Colors.white)),
                    content: const Text("Mohammed Shameem J\nAryaman Yadav\nShivam Chandra\nKrishna Santhanam\n\n(Wait, that's only 4? 😂)", style: TextStyle(color: Colors.white70)),
                  ));
                  eggTaps = 0;
                }
              },
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const CircleAvatar(radius: 60, backgroundColor: Color(0xFF6200EA), child: Icon(Icons.person, size: 60, color: Colors.white)),
                  Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.verified, color: Colors.blue)),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text("Reg: $id", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFFFD700), borderRadius: BorderRadius.circular(20)), child: const Text("Saints Row III School", style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 30),
            ListTile(leading: const Icon(Icons.headset_mic), title: const Text("Help & Support"), onTap: _showSupport, trailing: const Icon(Icons.chevron_right)),
            ListTile(leading: const Icon(Icons.info_outline), title: const Text("App Version"), subtitle: const Text("v4.0.1 (Ultimate)"), trailing: const Icon(Icons.chevron_right)),
            ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Logout", style: TextStyle(color: Colors.red)), onTap: () async {
              final prefs = await SharedPreferences.getInstance(); await prefs.clear();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
            }),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
