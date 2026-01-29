import 'package:flutter/material.dart';
import 'package:srm_kitchen/screens/menu_screen.dart';
import 'package:srm_kitchen/screens/cart_screen.dart';
import 'package:srm_kitchen/screens/wallet_screen.dart';
import 'package:srm_kitchen/screens/profile_screen.dart';
import 'package:srm_kitchen/screens/chat_screen.dart';
import 'package:srm_kitchen/services/tutorial_service.dart';

class MainScreen extends StatefulWidget {
  final bool startTutorial;
  const MainScreen({super.key, this.startTutorial = false});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0;

  final List<Widget> _tabs = [
    const MenuScreen(),
    const CartScreen(),
    const WalletScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.startTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runTutorial());
    }
  }

  void _runTutorial() async {
    // Step 1: Menu Screen - Veg Filter
    // Note: We need GlobalKeys to be accessible. Since I can't inject them easily into inner widgets without refactoring everything to accept keys,
    // I will use a simple workaround: I'll assume the keys are registered if the widget tree is built.
    // BUT, the inner widgets (MenuScreen) create their own keys inside build().
    // To fix this properly, I should have defined keys globally or passed them.
    // For this prototype, I will try to find the widget by type or just show a generic overlay if I can't find rect.

    // Actually, let's just simulate the flow with messages since finding rects of internal items is hard without refactoring.
    // Wait, I can't find rects without keys.
    // I will refactor MenuScreen to use keys for specific items if possible, but they are inside a stateless widget.
    // Okay, I added keys to MenuScreen in previous step ('filter_veg', 'filter_fav', 'cat_express').
    // But how to access them? They are local to that widget instance.
    // Since MainScreen builds MenuScreen, the keys need to be passed or be global.

    // Let's use a simpler "Presentation Mode" dialog sequence that auto-navigates.

    await _showDemoDialog("Welcome to SRM Kitchen v3", "Let's take a quick tour of the features.");

    // 1. Menu
    setState(() => _idx = 0);
    await Future.delayed(const Duration(milliseconds: 500));
    await _showDemoDialog("Smart Menu", "• Filter by Veg/Non-Veg\n• 'Favorites' toggle for quick access\n• 'Express' category for <2min food.");

    // 2. Cart
    setState(() => _idx = 1);
    await Future.delayed(const Duration(milliseconds: 500));
    await _showDemoDialog("Cart & Coupons", "• Apply coupons like 'SRM50'\n• Swipe to Pay\n• Track order status in History.");

    // 3. Wallet
    setState(() => _idx = 2);
    await Future.delayed(const Duration(milliseconds: 500));
    await _showDemoDialog("Digital Wallet", "• Secure payments\n• Add money via UPI/Card\n• Transaction history.");

    await _showDemoDialog("All Set!", "You are ready to use SRM Kitchen.");
  }

  Future<void> _showDemoDialog(String title, String content) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("NEXT"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _tabs),
      floatingActionButton: _idx == 0 ? FloatingActionButton( // Only show on Menu
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const ChatScreen(),
          );
        },
        backgroundColor: const Color(0xFF6200EA),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ) : null,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)
          ),
          indicatorColor: const Color(0xFF6200EA).withOpacity(0.1),
          iconTheme: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(color: Color(0xFF6200EA));
            }
            return const IconThemeData(color: Colors.grey);
          }),
        ),
        child: NavigationBar(
          selectedIndex: _idx,
          onDestinationSelected: (i) => setState(() => _idx = i),
          backgroundColor: Theme.of(context).cardColor,
          elevation: 10,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.restaurant_menu), label: "Menu"),
            NavigationDestination(
                icon: Icon(Icons.receipt_long), label: "Orders"),
            NavigationDestination(
                icon: Icon(Icons.account_balance_wallet), label: "Wallet"),
            NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}
