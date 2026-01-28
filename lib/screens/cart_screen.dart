import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:srm_kitchen/providers/cart_provider.dart';
import 'package:srm_kitchen/providers/user_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with SingleTickerProviderStateMixin {
  final _couponCtrl = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final user = Provider.of<UserProvider>(context, listen: false);

    if (cart.cart.isEmpty) return;

    final total = cart.total;

    if (user.walletBalance < total) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Insufficient Balance! Add money to wallet."),
          backgroundColor: Colors.red));
      return;
    }

    final success = await user.deductMoney(total, "Food Order");
    if (!success) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Payment Failed!"),
          backgroundColor: Colors.red));
      return;
    }

    // Show Success Dialog with Animation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const CheckoutSuccessDialog(),
    );

    await cart.checkout(total);

    // The dialog inside cart.checkout logic is handled by UI state listening or manual?
    // In my previous step I updated CartProvider to have checkoutState.
    // Actually, let's look at the logic.
    // Provider handles state. UI reacts.

    // Wait for provider to finish "loading"
    // Ideally we shouldn't await cart.checkout here if it doesn't return immediately or if we want custom UI.
    // The provider `checkout` method I wrote has a delay and sets state.
    // But since I'm showing a custom dialog here, I might want to coordinate.

    // Let's rely on the Dialog's internal logic or close it manually.
    if (mounted) Navigator.pop(context); // Close the checkout dialog

    // Then switch to History tab
    DefaultTabController.of(context).animateTo(1);
  }

  Widget _buildStep(String title, bool isActive, bool isCompleted, IconData icon) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Icon(icon,
            color: isCompleted ? Colors.green : (isActive ? Colors.orange : Colors.grey)),
        Container(width: 2, height: 30, color: Colors.grey[300]),
      ]),
      const SizedBox(width: 15),
      Text(title,
          style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Orders"),
          bottom: const TabBar(tabs: [Tab(text: "Cart"), Tab(text: "History")]),
        ),
        body: TabBarView(
          children: [
            // CART TAB
            Consumer<CartProvider>(
              builder: (context, cart, _) => cart.cart.isEmpty
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        const Text("Hungry? Add some food!", style: TextStyle(color: Colors.grey))
                      ],
                    ))
                  : Column(children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: cart.cart.length,
                          itemBuilder: (c, i) {
                            final ci = cart.cart[i];
                            return ListTile(
                              title: Text(ci.displayName),
                              subtitle: Row(children: [
                                IconButton(
                                    icon: const Icon(Icons.remove, size: 18),
                                    onPressed: () =>
                                        cart.updateQuantity(ci, -1)),
                                Text("${ci.quantity}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                    icon: const Icon(Icons.add, size: 18),
                                    onPressed: () => cart.updateQuantity(ci, 1)),
                              ]),
                              trailing: Text("₹${ci.totalPrice.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
                        ),
                        child: Column(children: [
                          if (cart.discount > 0)
                             Container(
                               padding: const EdgeInsets.all(10),
                               margin: const EdgeInsets.only(bottom: 10),
                               decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                               child: Row(children: [
                                 const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                 const SizedBox(width: 8),
                                 Text("SRM Coupon Applied! -₹${cart.discount.toInt()}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                               ])
                             ),
                          Row(children: [
                            Expanded(
                                child: TextField(
                                    controller: _couponCtrl,
                                    decoration: InputDecoration(
                                        hintText: "Enter Code (e.g. SRM50)",
                                        isDense: true,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))))),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                if(cart.applyCoupon(_couponCtrl.text)) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("YAY! Coupon Applied!")));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Coupon"), backgroundColor: Colors.red));
                                }
                              },
                              child: const Text("APPLY")
                            )
                          ]),
                          const SizedBox(height: 20),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Total Amount", style: TextStyle(fontSize: 16)),
                                Text(
                                  "₹${cart.total.toInt()}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF6200EA)),
                                )
                              ]),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6200EA),
                                  foregroundColor: Colors.white,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              onPressed: _placeOrder,
                              child: const Text("SWIPE TO PAY (DEMO: TAP)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ),
                          )
                        ]),
                      )
                    ]),
            ),

            // HISTORY TAB
            Consumer<CartProvider>(
              builder: (context, cart, _) => cart.history.isEmpty ?
              Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        const Text("No past orders.", style: TextStyle(color: Colors.grey))
                      ],
                    )) :
              ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: cart.history.length,
              itemBuilder: (context, index) {
                final o = cart.history[index];
                final mins = DateTime.now().difference(o.timestamp).inMinutes;
                bool cooking = mins >= 0; // Immediate cooking for demo
                bool ready = mins >= 1; // Fast ready for demo

                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ExpansionTile(
                    title: Text("Order #${o.id}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle:
                        Text(DateFormat('dd MMM, hh:mm a').format(o.timestamp)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(children: [
                          _buildStep("Order Placed", true, cooking, Icons.receipt),
                          _buildStep("Cooking", cooking, ready, Icons.soup_kitchen),
                          _buildStep("Ready to Pickup", ready, ready, Icons.check_circle),
                          const SizedBox(height: 10),

                          ...o.items.map((i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                                children: [
                                  const Icon(Icons.fastfood, size: 14, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text("${i.displayName} x${i.quantity}")),
                                  Text("₹${i.totalPrice.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                          )),

                          const Divider(height: 30),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Total Paid"),
                                Text("₹${o.paid.toInt()}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.green))
                              ]),

                          const SizedBox(height: 20),
                          if (ready) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
                              child: QrImageView(data: o.id, size: 120, backgroundColor: Colors.white)
                            ),
                            const SizedBox(height: 10),
                            const Text("SHOW TO COUNTER",
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            const SizedBox(height: 20),
                            const Text("Rate your meal:", style: TextStyle(fontWeight: FontWeight.w500)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (s) {
                                return IconButton(
                                  icon: Icon(
                                      s < (o.rating ?? 0)
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: Colors.amber, size: 30),
                                  onPressed: () => cart.rateOrder(o, s + 1),
                                );
                              }),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                cart.reorder(o);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Items added to cart!")));
                                DefaultTabController.of(context).animateTo(0);
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text("Reorder This Meal")
                            )
                          ] else
                            const Column(
                              children: [
                                LinearProgressIndicator(),
                                SizedBox(height: 5),
                                Text("Preparing...", style: TextStyle(color: Colors.grey, fontSize: 12))
                              ],
                            ),
                        ]),
                      )
                    ],
                  ),
                );
              },
            ),)
          ],
        ),
      ),
    );
  }
}

class CheckoutSuccessDialog extends StatefulWidget {
  const CheckoutSuccessDialog({super.key});

  @override
  State<CheckoutSuccessDialog> createState() => _CheckoutSuccessDialogState();
}

class _CheckoutSuccessDialogState extends State<CheckoutSuccessDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.elasticOut)));
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizeTransition(
                    sizeFactor: _checkAnimation,
                    axis: Axis.horizontal,
                    child: const Icon(Icons.check, color: Colors.white, size: 50),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Order Placed!",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 10),
            const Text("Your food is being prepared.",
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
