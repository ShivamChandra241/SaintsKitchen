import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

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
        primaryColor: const Color(0xFF6200EA), // Deep Purple
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6200EA),
          secondary: const Color(0xFFFFD700), // Gold
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const SplashScreen(),
    );
  }
}

// --- 1. SPLASH SCREEN (Check Login) ---
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
    await Future.delayed(const Duration(seconds: 2)); // Logo duration
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => isLoggedIn ? const HomePage() : const LoginScreen(),
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
            const SizedBox(height: 10),
            Text("Saints Kitchen", style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// --- 2. LOGIN SCREEN ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  bool isLoading = false;

  Future<void> _login() async {
    if (_nameController.text.isEmpty || _idController.text.isEmpty) return;

    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Fake network delay

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('username', _nameController.text);
    await prefs.setString('userid', _idController.text);
    // Initialize wallet with 0 if it doesn't exist
    if (!prefs.containsKey('wallet')) {
      await prefs.setDouble('wallet', 0.0);
    }

    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6200EA), Color(0xFF9900F0)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(blurRadius: 15, color: Colors.black26)]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Student Login", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person), border: OutlineInputBorder())),
                const SizedBox(height: 15),
                TextField(controller: _idController, decoration: const InputDecoration(labelText: "Register Number", prefixIcon: Icon(Icons.badge), border: OutlineInputBorder())),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6200EA), foregroundColor: Colors.white),
                    onPressed: isLoading ? null : _login,
                    child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("ENTER KITCHEN"),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- 3. HOME PAGE ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double walletBalance = 0.0;
  String username = "";
  List<FoodItem> cart = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      walletBalance = prefs.getDouble('wallet') ?? 0.0;
      username = prefs.getString('username') ?? "Student";
    });
  }

  void addToCart(FoodItem item) {
    setState(() => cart.add(item));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${item.name} added!"), duration: const Duration(milliseconds: 500)));
  }

  void openWalletPage() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletPage()));
    _loadData(); // Refresh balance when returning
  }

  void openProfilePage() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hi, $username", style: const TextStyle(fontSize: 14)),
            const Text("Saints Kitchen", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          // Wallet Chip
          GestureDetector(
            onTap: openWalletPage,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xFF6200EA), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.white, size: 16),
                  const SizedBox(width: 5),
                  Text("₹${walletBalance.toInt()}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Profile Icon
          IconButton(
            icon: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
            onPressed: openProfilePage,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.8, crossAxisSpacing: 15, mainAxisSpacing: 15),
              itemCount: menu.length,
              itemBuilder: (context, index) {
                final item = menu[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 50, color: const Color(0xFF6200EA)),
                      const SizedBox(height: 10),
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("₹${item.price}", style: const TextStyle(color: Colors.grey)),
                      ElevatedButton(
                        onPressed: () => addToCart(item),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black, shape: const StadiumBorder()),
                        child: const Text("Add"),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
          if (cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)], borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total: ₹${cart.fold(0.0, (s, i) => s + i.price)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6200EA), foregroundColor: Colors.white),
                    onPressed: () async {
                      double total = cart.fold(0.0, (s, i) => s + i.price);
                      final prefs = await SharedPreferences.getInstance();
                      double currentBalance = prefs.getDouble('wallet') ?? 0.0;
                      
                      if (currentBalance >= total) {
                        await prefs.setDouble('wallet', currentBalance - total);
                        setState(() { walletBalance -= total; cart.clear(); });
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderTrackingPage()));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Insufficient Balance! Tap Wallet to add money.")));
                      }
                    },
                    child: const Text("PAY & ORDER"),
                  )
                ],
              ),
            )
        ],
      ),
    );
  }
}

// --- 4. WALLET PAGE ---
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});
  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  double currentBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => currentBalance = prefs.getDouble('wallet') ?? 0.0);
  }

  Future<void> _addMoney(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    double newBalance = currentBalance + amount;
    await prefs.setDouble('wallet', newBalance);
    setState(() => currentBalance = newBalance);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added ₹$amount to wallet!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Wallet")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6200EA), Color(0xFF8F00FF)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  const Text("Current Balance", style: TextStyle(color: Colors.white70)),
                  Text("₹${currentBalance.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text("Add Money to Wallet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _moneyButton(100),
                _moneyButton(200),
                _moneyButton(500),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _moneyButton(double amount) {
    return GestureDetector(
      onTap: () => _addMoney(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF6200EA)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text("+ ₹${amount.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6200EA))),
      ),
    );
  }
}

// --- 5. PROFILE PAGE (With Easter Egg) ---
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "";
  String id = "";
  int eggCounter = 0; // Counts taps for Easter Egg

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('username') ?? "Student";
      id = prefs.getString('userid') ?? "Unknown";
    });
  }

  void _handleEggTap() {
    setState(() => eggCounter++);
    if (eggCounter == 5) {
      // Trigger Easter Egg
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("⚡ TEAM FANTASTIC 6 ⚡"),
          content: const Text(
            "Mohammed Shameem J\nRA2411028020104\n\n"
            "Aryaman Yadav\nRA2411028020086\n\n"
            "Shivam Chandra\nRA2311028020049\n\n"
            "Krishna Santhanam\nRA2411028020136",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
        ),
      );
      eggCounter = 0; // Reset
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Column(
        children: [
          const SizedBox(height: 30),
          Center(
            child: GestureDetector(
              onTap: _handleEggTap,
              child: const CircleAvatar(
                radius: 60,
                backgroundColor: Color(0xFF6200EA),
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text("ID: $id", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFFFD700), borderRadius: BorderRadius.circular(10)),
            child: const Text("Saints Row III School", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 40),
          ListTile(leading: const Icon(Icons.support_agent), title: const Text("Help & Support"), onTap: () {}),
          ListTile(leading: const Icon(Icons.info_outline), title: const Text("About App"), onTap: () {}),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // Wipes data
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
          ),
        ],
      ),
    );
  }
}

// --- 6. MOCK DATA & TRACKING PAGE ---
class OrderTrackingPage extends StatelessWidget {
  const OrderTrackingPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order Status")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            const Text("Order Placed!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Show this token at counter:"),
            const SizedBox(height: 20),
            QrImageView(data: 'SAINTS-VERIFIED', size: 200),
          ],
        ),
      ),
    );
  }
}

class FoodItem {
  final String name;
  final double price;
  final IconData icon;
  FoodItem(this.name, this.price, this.icon);
}

final List<FoodItem> menu = [
  FoodItem("Burger", 60.0, Icons.lunch_dining),
  FoodItem("Pizza", 80.0, Icons.local_pizza),
  FoodItem("Fries", 50.0, Icons.fastfood),
  FoodItem("Cola", 20.0, Icons.local_drink),
];
