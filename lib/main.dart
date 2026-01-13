import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';

// --- DATA MODELS ---
class FoodItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final String imageEmoji; // Using emojis as "images" for simplicity
  final bool isVeg;
  final String description;

  FoodItem(this.id, this.name, this.category, this.price, this.imageEmoji, this.isVeg, this.description);
  
  // Convert to Map for storage
  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'category': category, 'price': price, 
    'imageEmoji': imageEmoji, 'isVeg': isVeg, 'description': description
  };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
    json['id'], json['name'], json['category'], json['price'], 
    json['imageEmoji'], json['isVeg'], json['description']
  );
}

class Order {
  final String id;
  final List<FoodItem> items;
  final double total;
  final DateTime timestamp;
  
  Order(this.id, this.items, this.total, this.timestamp);

  Map<String, dynamic> toJson() => {
    'id': id,
    'items': items.map((i) => i.toJson()).toList(),
    'total': total,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    json['id'],
    (json['items'] as List).map((i) => FoodItem.fromJson(i)).toList(),
    json['total'],
    DateTime.parse(json['timestamp']),
  );
}

// --- MOCK MENU ---
final List<FoodItem> fullMenu = [
  // Meals
  FoodItem("1", "Classic Burger", "Meals", 60, "🍔", false, "Juicy grilled chicken patty with saints secret sauce."),
  FoodItem("2", "Cheese Pizza", "Meals", 80, "🍕", true, "Double cheese burst with herb crust."),
  FoodItem("3", "Veg Biryani", "Meals", 120, "🍚", true, "Aromatic basmati rice with fresh garden veggies."),
  FoodItem("4", "Chicken Wrap", "Meals", 90, "🌯", false, "Spicy chicken strips wrapped in soft tortilla."),
  
  // Drinks
  FoodItem("5", "Cola", "Drinks", 20, "🥤", true, "Chilled fizzy cola with ice."),
  FoodItem("6", "Cold Coffee", "Drinks", 50, "🧋", true, "Creamy blended coffee with chocolate chips."),
  FoodItem("7", "Mango Shake", "Drinks", 60, "🥭", true, "Fresh alphonso mango pulp blend."),
  
  // Snacks
  FoodItem("8", "Peri Peri Fries", "Snacks", 50, "🍟", true, "Crispy fries tossed in spicy peri peri mix."),
  FoodItem("9", "Donut", "Dessert", 45, "🍩", false, "Chocolate glazed donut with sprinkles."),
  FoodItem("10", "Sandwich", "Snacks", 40, "🥪", true, "Grilled vegetable sandwich with mayo."),
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
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6200EA), secondary: const Color(0xFFFFD700)),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const SplashScreen(),
    );
  }
}

// --- 1. SPLASH & LOGIN ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => isLoggedIn ? const MainScreen() : const LoginScreen()));
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
            const Icon(Icons.restaurant, color: Colors.white, size: 80),
            const SizedBox(height: 10),
            Text("SAINTS KITCHEN", style: GoogleFonts.bebasNeue(fontSize: 40, color: Colors.white, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}

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
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6200EA), Color(0xFF900C3F)])),
        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Student Login", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Name", prefixIcon: Icon(Icons.person), border: OutlineInputBorder())),
                  const SizedBox(height: 15),
                  TextField(controller: _idCtrl, decoration: const InputDecoration(labelText: "Reg No", prefixIcon: Icon(Icons.badge), border: OutlineInputBorder())),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6200EA), foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
                    onPressed: _loading ? null : _login,
                    child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("ENTER"),
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

// --- 2. MAIN SCREEN (Bottom Nav) ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0;
  List<FoodItem> cart = [];
  
  void addToCart(FoodItem item) {
    setState(() => cart.add(item));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("${item.name} added to cart!"), 
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 600)
    ));
  }

  void clearCart() => setState(() => cart.clear());

  @override
  Widget build(BuildContext context) {
    final tabs = [
      MenuPage(onAddToCart: addToCart),
      OrdersPage(currentCart: cart, onClearCart: clearCart),
      const ProfilePage(),
    ];

    return Scaffold(
      body: tabs[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.restaurant_menu), label: "Menu"),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: "Orders"),
          NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// --- 3. MENU PAGE (Categories & Search) ---
class MenuPage extends StatefulWidget {
  final Function(FoodItem) onAddToCart;
  const MenuPage({super.key, required this.onAddToCart});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String selectedCat = "All";
  String searchQuery = "";
  final categories = ["All", "Meals", "Drinks", "Snacks", "Dessert"];

  List<FoodItem> get filteredItems {
    return fullMenu.where((item) {
      final matchesCat = selectedCat == "All" || item.category == selectedCat;
      final matchesSearch = item.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();
  }

  void _showProductDetails(FoodItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(25),
          children: [
            Center(child: Text(item.imageEmoji, style: const TextStyle(fontSize: 100))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text("₹${item.price}", style: const TextStyle(fontSize: 24, color: Color(0xFF6200EA), fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.circle, size: 12, color: item.isVeg ? Colors.green : Colors.red),
              const SizedBox(width: 5),
              Text(item.isVeg ? "Pure Veg" : "Non-Veg", style: TextStyle(color: Colors.grey[600])),
            ]),
            const SizedBox(height: 20),
            const Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(item.description, style: TextStyle(color: Colors.grey[600], height: 1.5)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6200EA), foregroundColor: Colors.white),
                onPressed: () {
                  widget.onAddToCart(item);
                  Navigator.pop(context);
                },
                child: const Text("ADD TO CART", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => searchQuery = v),
                    decoration: InputDecoration(
                      hintText: "Search hungry...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Categories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: FilterChip(
                  label: Text(cat),
                  selected: selectedCat == cat,
                  onSelected: (b) => setState(() => selectedCat = cat),
                  selectedColor: const Color(0xFFFFD700),
                  checkmarkColor: Colors.black,
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 10),
          // Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 15, mainAxisSpacing: 15
              ),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return GestureDetector(
                  onTap: () => _showProductDetails(item),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.imageEmoji, style: const TextStyle(fontSize: 40)),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(item.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Text("₹${item.price}", style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(10)),
                          child: const Text("ADD +", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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

// --- 4. ORDERS PAGE (Cart + Active Tracking) ---
class OrdersPage extends StatefulWidget {
  final List<FoodItem> currentCart;
  final VoidCallback onClearCart;
  const OrdersPage({super.key, required this.currentCart, required this.onClearCart});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Order> orderHistory = [];
  bool showHistory = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('order_history');
    if (historyJson != null) {
      final List<dynamic> decoded = jsonDecode(historyJson);
      setState(() {
        orderHistory = decoded.map((j) => Order.fromJson(j)).toList();
        // Sort by newest
        orderHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });
    }
  }

  Future<void> _placeOrder() async {
    if (widget.currentCart.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final double wallet = prefs.getDouble('wallet') ?? 0.0;
    final double total = widget.currentCart.fold(0, (sum, i) => sum + i.price);

    if (wallet < total) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Insufficient Balance! Top up in Profile.")));
      return;
    }

    // Process Payment
    await prefs.setDouble('wallet', wallet - total);
    
    // Create Order
    final newOrder = Order(
      "SK-${Random().nextInt(9000) + 1000}", // Random ID like SK-8822
      List.from(widget.currentCart),
      total,
      DateTime.now(),
    );

    // Save to History
    final updatedHistory = [newOrder, ...orderHistory];
    await prefs.setString('order_history', jsonEncode(updatedHistory.map((e) => e.toJson()).toList()));

    widget.onClearCart();
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
          bottom: const TabBar(
            tabs: [Tab(text: "Current Cart"), Tab(text: "Track Orders")],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: CART
            widget.currentCart.isEmpty
                ? const Center(child: Text("Cart is Empty", style: TextStyle(color: Colors.grey)))
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: widget.currentCart.length,
                          itemBuilder: (context, index) {
                            final item = widget.currentCart[index];
                            return ListTile(
                              leading: Text(item.imageEmoji, style: const TextStyle(fontSize: 24)),
                              title: Text(item.name),
                              trailing: Text("₹${item.price}"),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)]),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Total: ₹${widget.currentCart.fold(0.0, (s, i) => s + i.price)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6200EA), foregroundColor: Colors.white),
                              onPressed: _placeOrder,
                              child: const Text("PAY & ORDER"),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
            
            // Tab 2: TRACKING HISTORY
            orderHistory.isEmpty
                ? const Center(child: Text("No past orders", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: orderHistory.length,
                    itemBuilder: (context, index) {
                      final order = orderHistory[index];
                      // Calculate status based on Time
                      final minsPassed = DateTime.now().difference(order.timestamp).inMinutes;
                      String status = "Placed";
                      Color statusColor = Colors.blue;
                      double progress = 0.2;

                      if (minsPassed >= 1 && minsPassed < 3) {
                        status = "Cooking"; statusColor = Colors.orange; progress = 0.6;
                      } else if (minsPassed >= 3) {
                        status = "Ready to Pickup"; statusColor = Colors.green; progress = 1.0;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ExpansionTile(
                          title: Text("Order #${order.id}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(DateFormat('dd MMM, hh:mm a').format(order.timestamp)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(value: progress, color: statusColor, backgroundColor: Colors.grey[200]),
                                  const SizedBox(height: 15),
                                  ...order.items.map((i) => Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [Text("1x ${i.name}"), Text("₹${i.price}")],
                                  )).toList(),
                                  const Divider(),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    const Text("Total Paid", style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text("₹${order.total}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ]),
                                  if (status == "Ready to Pickup") ...[
                                    const SizedBox(height: 20),
                                    Center(
                                      child: Column(
                                        children: [
                                          QrImageView(data: order.id, size: 120),
                                          const SizedBox(height: 5),
                                          const Text("Show this at Counter", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                    )
                                  ]
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

// --- 5. PROFILE PAGE (Wallet & Easter Egg) ---
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "Student";
  String id = "ID";
  double wallet = 0.0;
  int eggTaps = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? "Student";
      id = prefs.getString('id') ?? "ID";
      wallet = prefs.getDouble('wallet') ?? 0.0;
    });
  }

  Future<void> _addMoney(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('wallet', wallet + amount);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added ₹$amount")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                setState(() => eggTaps++);
                if (eggTaps == 5) {
                  showDialog(context: context, builder: (_) => AlertDialog(
                    title: const Text("⚡ TEAM FANTASTIC 6"),
                    content: const Text("Mohammed Shameem J\nAryaman Yadav\nShivam Chandra\nKrishna Santhanam"),
                  ));
                  eggTaps = 0;
                }
              },
              child: const CircleAvatar(radius: 50, backgroundColor: Color(0xFF6200EA), child: Icon(Icons.person, size: 50, color: Colors.white)),
            ),
            const SizedBox(height: 10),
            Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(id, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6200EA), Color(0xFF8F00FF)]), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Wallet Balance", style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 5),
                    Text("Saints Pay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ]),
                  Text("₹${wallet.toInt()}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _moneyBtn(100), _moneyBtn(200), _moneyBtn(500)
            ]),
            const SizedBox(height: 30),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _moneyBtn(double amt) {
    return OutlinedButton(
      onPressed: () => _addMoney(amt),
      child: Text("+ ₹${amt.toInt()}"),
    );
  }
}
