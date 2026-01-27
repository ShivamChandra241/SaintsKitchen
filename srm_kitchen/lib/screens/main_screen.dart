import 'package:flutter/material.dart';
import 'package:srm_kitchen/screens/menu_screen.dart';
import 'package:srm_kitchen/screens/cart_screen.dart';
import 'package:srm_kitchen/screens/wallet_screen.dart';
import 'package:srm_kitchen/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
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
    );
  }
}
