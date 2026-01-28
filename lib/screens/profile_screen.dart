import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:srm_kitchen/providers/user_provider.dart';
import 'package:srm_kitchen/theme/theme_provider.dart';
import 'login_screen.dart';
import 'presentation_screen.dart';

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
        title: const Text("About SRM Kitchen"),
        content: const Text(
          "SRM Kitchen v2.0 (Flashy Hive Edition)\n\n"
          "Built by Team Fantastic 6 to reduce canteen overcrowding and waiting time.\n\n"
          "Features:\n"
          "• Hive Database\n"
          "• Express Menu\n"
          "• Favorites & Filters\n"
          "• Dark Mode\n\n"
          "Made for SRM University.",
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
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25))
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          const Text("SRM Support",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.warning, color: Colors.white)),
            title: const Text("Raise a Complaint"),
            subtitle: const Text("Food quality, Payment issues"),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Ticket #SR-${Random().nextInt(999)} Created. Admin will check.")),
              );
            },
          ),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.feedback, color: Colors.white)),
            title: const Text("Give Feedback"),
            subtitle: const Text("Tell us what you think"),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Thanks for your feedback!")),
              );
            },
          ),
        ]),
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
      body: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 30),
          GestureDetector(
            onTap: () {
              setState(() => eggTaps++);
              if (eggTaps == 5) {
                eggTaps = 0;
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PresentationScreen()));
              }
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6200EA), width: 3)
              ),
              child: const CircleAvatar(
                radius: 60,
                backgroundColor: Color(0xFF6200EA),
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(user.name,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text("Reg: ${user.id}", style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 30),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
            ),
            child: Column(
              children: [
                ListTile(
                    leading: const Icon(Icons.dark_mode, color: Colors.purple),
                    title: const Text("Dark Mode"),
                    trailing: Switch(
                      value: theme.isDark,
                      onChanged: (v) => theme.toggleTheme(),
                      activeColor: Colors.purple,
                    ),
                    onTap: () => theme.toggleTheme(),
                ),
                const Divider(height: 1),
                ListTile(
                    leading: const Icon(Icons.notifications, color: Colors.orange),
                    title: const Text("Notifications"),
                    trailing: Switch(value: true, onChanged: (v){}, activeColor: Colors.orange),
                    onTap: () {}),
                const Divider(height: 1),
                ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.red),
                    title: const Text("Saved Addresses"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {}),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
            ),
            child: Column(
              children: [
                ListTile(
                    leading: const Icon(Icons.headset_mic, color: Colors.blue),
                    title: const Text("Help & Support"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showSupport(context)),
                const Divider(height: 1),
                ListTile(
                    leading: const Icon(Icons.info, color: Colors.teal),
                    title: const Text("About Us"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showAbout(context)),
              ],
            ),
          ),

          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text("LOGOUT"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: () => _logout(context),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text("v2.0.0 • Powered by Hive", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }
}
