import 'package:flutter/material.dart';

void main() {
  runApp(const FoodAppV8());
}

// ---------------------------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------------------------

class FoodItem {
  final String id;
  final String name;
  final double price;
  final String description; // Added for completeness

  FoodItem({
    required this.id,
    required this.name,
    required this.price,
    this.description = 'Delicious food item',
  });
}

class OrderItem {
  final String id;
  final List<FoodItem> items;
  final double totalAmount;
  final String address;
  final DateTime date;
  double rating; // Mutable to allow updates

  OrderItem({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.address,
    required this.date,
    this.rating = 0.0,
  });
}

// ---------------------------------------------------------------------------
// MAIN APP WIDGET
// ---------------------------------------------------------------------------

class FoodAppV8 extends StatelessWidget {
  const FoodAppV8({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food Delivery V8',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: const MainScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// MAIN SCREEN (STATE & LOGIC)
// ---------------------------------------------------------------------------

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // --- STATE VARIABLES ---
  
  // Wallet & Cart
  double walletBalance = 1500.0; // Starting balance
  List<FoodItem> cart = [];
  List<OrderItem> orderHistory = [];

  // Address Logic
  String? selectedAddress;
  final List<String> addresses = [
    "Home - 123 Green St, Apt 4B",
    "Office - Tech Park, Building 5",
    "Partner's House - 789 Lake View",
  ];

  // Coupon Logic
  bool isCouponApplied = false;
  final String couponCode = "SAVE50";
  final double deliveryFee = 40.0;
  final double couponDiscount = 50.0;

  // --- MENU DATA ---
  final List<FoodItem> menu = [
    FoodItem(id: '1', name: 'Chicken Pizza', price: 299, description: 'Cheesy chicken loaded pizza'),
    FoodItem(id: '2', name: 'Veg Burger', price: 129, description: 'Crispy vegetable patty'),
    FoodItem(id: '3', name: 'Fried Chicken Bucket', price: 499, description: '6 pieces of crispy chicken'),
    FoodItem(id: '4', name: 'Iced Coffee', price: 149, description: 'Cold brew with milk'),
    FoodItem(id: '5', name: 'Pepperoni Pizza', price: 349, description: 'Classic pork pepperoni'),
    FoodItem(id: '6', name: 'Chicken Pasta', price: 219, description: 'White sauce pasta with chicken'),
  ];

  // --- LOGIC FUNCTIONS ---

  /// Fix #2: Smart Icon Logic based on Name
  IconData getIconForName(String name) {
    String lower = name.toLowerCase();
    if (lower.contains('pizza')) return Icons.local_pizza;
    if (lower.contains('burger')) return Icons.lunch_dining;
    if (lower.contains('coffee') || lower.contains('tea') || lower.contains('drink')) return Icons.local_cafe;
    if (lower.contains('chicken') && !lower.contains('pizza') && !lower.contains('burger')) return Icons.set_meal;
    if (lower.contains('ice cream') || lower.contains('dessert')) return Icons.icecream;
    return Icons.restaurant; // Default fallback
  }

  /// Fix #1: Dynamic Calculation (Cart + Delivery - Coupon)
  double get cartItemTotal {
    return cart.fold(0, (sum, item) => sum + item.price);
  }

  double get finalTotalAmount {
    if (cart.isEmpty) return 0.0;
    
    double total = cartItemTotal + deliveryFee;
    
    // Only apply discount if the total is high enough to warrant it (optional logic, but good for safety)
    if (isCouponApplied) {
      total -= couponDiscount;
    }
    
    return total < 0 ? 0 : total; // Never return negative amount
  }

  void addToCart(FoodItem item) {
    setState(() {
      cart.add(item);
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${item.name} added to cart"),
        duration: const Duration(milliseconds: 600),
        action: SnackBarAction(label: 'UNDO', onPressed: () {
          setState(() => cart.removeLast());
        }),
      ),
    );
  }

  void removeFromCart(int index) {
    setState(() {
      cart.removeAt(index);
    });
  }

  void toggleCoupon(bool value) {
    setState(() {
      isCouponApplied = value;
    });
  }

  /// Fix #4: Rating System Update
  void rateOrder(String orderId, double stars) {
    setState(() {
      final index = orderHistory.indexWhere((element) => element.id == orderId);
      if (index != -1) {
        orderHistory[index].rating = stars;
      }
    });
  }

  /// Fix #3, #5, #6: Checkout with Validation, Deduction, and Archiving
  void handleCheckout() {
    // 1. Check if empty
    if (cart.isEmpty) {
      _showError("Your cart is empty!");
      return;
    }

    // 2. Check Address (Fix #6)
    if (selectedAddress == null) {
      _showError("Please select a delivery address.");
      return;
    }

    // 3. Check Wallet Balance (Fix #5)
    if (walletBalance < finalTotalAmount) {
      _showError("Insufficient Funds! Need ₹${(finalTotalAmount - walletBalance).toStringAsFixed(0)} more.");
      return;
    }

    // 4. PROCESS ORDER
    setState(() {
      // Deduct Money
      walletBalance -= finalTotalAmount;

      // Add to History (Fix #3 - Saving snapshot of items)
      final newOrder = OrderItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        items: List.from(cart), // Copy current list
        totalAmount: finalTotalAmount,
        address: selectedAddress!,
        date: DateTime.now(),
      );
      
      // Add to start of list (newest first)
      orderHistory.insert(0, newOrder);

      // Clear Cart
      cart.clear();
      isCouponApplied = false;
    });

    // 5. Success Feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Order Placed Successfully!"),
        backgroundColor: Colors.green,
      ),
    );
    
    // Switch to Orders tab to see it
    setState(() {
      _selectedIndex = 2; 
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // --- NAVIGATION STATE ---
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildMenuPage(),
      _buildCartPage(),
      _buildOrdersPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? "Food Menu" : _selectedIndex == 1 ? "My Cart" : "Order History"),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Wallet: ₹${walletBalance.toStringAsFixed(0)}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
              ),
            ),
          )
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        indicatorColor: Colors.orange.shade200,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // PAGE 1: MENU
  // -------------------------------------------------------------------------
  Widget _buildMenuPage() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: menu.length,
      itemBuilder: (context, index) {
        final item = menu[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(getIconForName(item.name), color: Colors.deepOrange, size: 30),
            ),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text("₹${item.price}", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
              ],
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(10),
              ),
              onPressed: () => addToCart(item),
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // PAGE 2: CART (Where most fixes happen)
  // -------------------------------------------------------------------------
  Widget _buildCartPage() {
    if (cart.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("Your cart is empty", style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => _selectedIndex = 0),
              child: const Text("Browse Menu"),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Cart Items List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cart.length,
            separatorBuilder: (ctx, i) => const Divider(),
            itemBuilder: (context, index) {
              final item = cart[index];
              return ListTile(
                leading: Icon(getIconForName(item.name), color: Colors.grey[700]),
                title: Text(item.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("₹${item.price}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => removeFromCart(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Checkout Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Address Selector
              const Text("Deliver to:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedAddress,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  prefixIcon: Icon(Icons.location_on, color: Colors.deepOrange),
                ),
                hint: const Text("Select your address..."),
                items: addresses.map((addr) {
                  return DropdownMenuItem(value: addr, child: Text(addr, style: const TextStyle(fontSize: 14)));
                }).toList(),
                onChanged: (val) {
                  setState(() => selectedAddress = val);
                },
              ),

              const SizedBox(height: 16),

              // Coupon Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Apply Coupon '$couponCode'", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        const Text("Save ₹50 instantly", style: TextStyle(fontSize: 10, color: Colors.green)),
                      ],
                    ),
                    Switch(
                      value: isCouponApplied,
                      activeColor: Colors.green,
                      onChanged: toggleCoupon,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bill Breakdown
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("Item Total"),
                Text("₹$cartItemTotal"),
              ]),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("Delivery Fee"),
                Text("₹$deliveryFee"),
              ]),
              if (isCouponApplied)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text("Coupon Discount", style: TextStyle(color: Colors.green)),
                    Text("- ₹$couponDiscount", style: const TextStyle(color: Colors.green)),
                  ]),
                ),
              
              const Divider(height: 24),
              
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("Total Amount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text("₹$finalTotalAmount", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepOrange)),
              ]),

              const SizedBox(height: 16),

              // Checkout Button
              ElevatedButton(
                onPressed: handleCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("PLACE ORDER", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // PAGE 3: ORDERS (History & Rating)
  // -------------------------------------------------------------------------
  Widget _buildOrdersPage() {
    if (orderHistory.isEmpty) {
      return const Center(child: Text("No orders yet."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orderHistory.length,
      itemBuilder: (context, index) {
        final order = orderHistory[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: ID and Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Order #${order.id.substring(order.id.length - 6)}", 
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      "${order.date.day}/${order.date.month} ${order.date.hour}:${order.date.minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const Divider(),
                
                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(order.address, style: const TextStyle(color: Colors.black87))),
                  ],
                ),
                const SizedBox(height: 10),

                // Items List
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.deepOrange),
                      const SizedBox(width: 8),
                      Text(item.name),
                      const Spacer(),
                      Text("₹${item.price}", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                )),
                
                const Divider(),
                
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Amount Paid:", style: TextStyle(fontWeight: FontWeight.w600)),
                    Text("₹${order.totalAmount}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Rating Section (Fix #4)
                const Text("Rate this order:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (starIndex) {
                    return InkWell(
                      onTap: () => rateOrder(order.id, starIndex + 1.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Icon(
                          starIndex < order.rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
