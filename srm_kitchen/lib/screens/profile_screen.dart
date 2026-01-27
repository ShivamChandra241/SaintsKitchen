import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:srm_kitchen/providers/user_provider.dart';
import 'package:srm_kitchen/theme/theme_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int eggTaps = 0;

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("About Saints Kitchen"),
        content: const Text(
          "Saints Kitchen v1.0 (Hive Edition)\n\n"
          "Built by Team Fantastic 6 to reduce canteen overcrowding and waiting time.\n\n"
          "Features:\n"
          "• Hive Database\n"
          "• Provider State Management\n"
          "• Favorites & Filters\n"
          "• Dark Mode\n\n"
          "Made for Saints Row III School.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  void _showSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("Saints Support",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.warning),
            title: const Text("Raise a Complaint"),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Ticket #SR-${Random().nextInt(999)} Created.")),
              );
            },
          ),
        ]),
      ),
    );
  }

  void _showEasterEgg(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text("⚡ FANTASTIC 6 ⚡",
            style: TextStyle(color: Colors.white)),
        content: const Text(
          "Mohammed Shameem J\n"
          "Aryaman Yadav\n"
          "Shivam Chandra\n"
          "Krishna Santhanam\n\n"
          "\"Built for Saints, by Saints.\"",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final user = Provider.of<UserProvider>(context, listen: false);
    await user.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Center(
        child: Column(children: [
          const SizedBox(height: 30),
          GestureDetector(
            onTap: () {
              setState(() => eggTaps++);
              if (eggTaps == 5) {
                _showEasterEgg(context);
                eggTaps = 0;
              }
            },
            child: const CircleAvatar(
              radius: 60,
              backgroundColor: Color(0xFF6200EA),
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(user.name,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text("Reg: ${user.id}", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text("Dark Mode"),
              trailing: Switch(
                value: theme.isDark,
                onChanged: (v) => theme.toggleTheme(),
              ),
              onTap: () => theme.toggleTheme(),
          ),
          ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text("Notifications"),
              onTap: () {}),
          ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text("Saved Addresses"),
              onTap: () {}),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.headset_mic),
              title: const Text("Help & Support"),
              onTap: () => _showSupport(context)),
          ListTile(
              leading: const Icon(Icons.info),
              title: const Text("About Us"),
              onTap: () => _showAbout(context)),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            onTap: () => _logout(context),
          ),
        ]),
      ),
    );
  }
}
