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

class _CartScreenState extends State<CartScreen> {
  final _couponCtrl = TextEditingController();

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

    // Deduct Money first (optimistic)
    // We need order ID for transaction meta, but placeOrder generates it.
    // Let's generate a temporary ID or let placeOrder handle it.
    // Plan:
    // 1. Check balance (done)
    // 2. Place Order (generates ID)
    // 3. Deduct Money (using ID)
    // But if deduct fails? (Unlikely if balance checked).
    // Better: Transaction should happen.

    // Let's do:
    // 1. Calculate amount.
    // 2. Deduct from wallet with "Pending Order".
    // 3. Create Order.
    // 4. If Order creation fails, refund (not handling here).

    // Or simplified:
    // 1. Place order.
    // 2. Deduct.
    // The previous app did: Check balance -> Show animation -> Deduct -> Save Order.

    // I'll replicate:
    final success = await user.deductMoney(total, "New Order");
    if (!success) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Payment Failed!"),
          backgroundColor: Colors.red));
      return;
    }

    // Show Animation
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(), // Or success icon
            const SizedBox(height: 20),
            const Text("Processing Payment...",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ]),
        ),
      ),
    );

    await cart.placeOrder(total);

    if (mounted) Navigator.pop(context); // Close dialog

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order Placed! ₹${total.toInt()} deducted.")));
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
                  ? const Center(child: Text("Cart Empty"))
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
                                    icon: const Icon(Icons.remove),
                                    onPressed: () =>
                                        cart.updateQuantity(ci, -1)),
                                Text("${ci.quantity}"),
                                IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => cart.updateQuantity(ci, 1)),
                              ]),
                              trailing: Text("₹${ci.totalPrice.toInt()}"),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        color: Theme.of(context).cardColor,
                        child: Column(children: [
                          if (cart.discount > 0)
                             Container(
                               padding: const EdgeInsets.all(10),
                               color: Colors.green[100],
                               child: Row(children: [
                                 const Icon(Icons.check, color: Colors.green),
                                 Text(" Coupon Applied! -₹${cart.discount}", style: const TextStyle(color: Colors.green))
                               ])
                             ),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(
                                child: TextField(
                                    controller: _couponCtrl,
                                    decoration: const InputDecoration(
                                        hintText: "Code: SAINTS50",
                                        border: OutlineInputBorder()))),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                if(cart.applyCoupon(_couponCtrl.text)) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Coupon Applied!")));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Coupon"), backgroundColor: Colors.red));
                                }
                              },
                              child: const Text("APPLY")
                            )
                          ]),
                          const SizedBox(height: 10),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Total"),
                                Text(
                                  "₹${cart.total.toInt()}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 18),
                                )
                              ]),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6200EA),
                                  foregroundColor: Colors.white),
                              onPressed: _placeOrder,
                              child: const Text("PAY & ORDER"),
                            ),
                          )
                        ]),
                      )
                    ]),
            ),

            // HISTORY TAB
            Consumer<CartProvider>(
              builder: (context, cart, _) => ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: cart.history.length,
              itemBuilder: (context, index) {
                final o = cart.history[index];
                final mins = DateTime.now().difference(o.timestamp).inMinutes;
                bool cooking = mins >= 1;
                bool ready = mins >= 2;

                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: ExpansionTile(
                    title: Text("Order #${o.id}"),
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

                          ...o.items.map((i) => Row(
                                children: [
                                  const Icon(Icons.circle, size: 6),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text("${i.displayName} x${i.quantity}")),
                                  Text("₹${i.totalPrice.toInt()}"),
                                ],
                              )),

                          const Divider(),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Paid"),
                                Text("₹${o.paid.toInt()}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green))
                              ]),

                          const SizedBox(height: 10),
                          if (ready) ...[
                            QrImageView(data: o.id, size: 100, backgroundColor: Colors.white),
                            const SizedBox(height: 6),
                            const Text("SCAN AT COUNTER",
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            const Text("Rate your food:"),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (s) {
                                return IconButton(
                                  icon: Icon(
                                      s < (o.rating ?? 0)
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber),
                                  onPressed: () => cart.rateOrder(o, s + 1),
                                );
                              }),
                            ),
                          ] else
                            const LinearProgressIndicator(),
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
