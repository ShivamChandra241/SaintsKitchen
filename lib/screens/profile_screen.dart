import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:srm_kitchen/providers/user_provider.dart';
import 'package:srm_kitchen/theme/theme_provider.dart';
import 'package:srm_kitchen/services/tutorial_service.dart';
import 'login_screen.dart';

// Import screens to navigate to them
import 'main_screen.dart';

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
          "SRM Kitchen v3.0\n\n"
          "Built by Team Fantastic 6.\n\n"
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

  void _showDietaryPrefs(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Dietary Preferences", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            CheckboxListTile(value: true, onChanged: (v){}, title: const Text("Vegetarian")),
            CheckboxListTile(value: false, onChanged: (v){}, title: const Text("Halal")),
            CheckboxListTile(value: false, onChanged: (v){}, title: const Text("Gluten Free")),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: ()=>Navigator.pop(context), child: const Text("SAVE")))
          ],
        ),
      )
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

  void _startTutorial() {
    // Navigate to Home first (Index 0)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()), // Logic inside mainscreen will handle navigation if we pass args?
      (r) => false
    );

    // We need to wait for frame to build MainScreen
    Future.delayed(const Duration(milliseconds: 500), () {
      // Since we don't have direct access to keys in MainScreen easily from here without advanced state management or passing keys,
      // I'll rely on finding keys by Type or assume they are in tree.
      // BUT keys must be global or passed down.
      // Strategy: Use GlobalKeys defined in a singleton or static class?
      // Simpler: Just define keys in GlobalVariables for the demo.
    });
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
                // Start Tutorial Flow
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Presentation Mode Activated!")));
                // This requires context of the screen where keys are.
                // We will navigate to MainScreen and trigger it there?
                // Or just show a Dialog explaining the flow for now if wiring keys is too complex.
                // Implementation: I'll use a hack. I will assume the keys are available in the widget tree if I navigate.
                // Actually, I'll pass a flag to MainScreen.
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen(startTutorial: true)),
                  (r) => false,
                );
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
                    leading: const Icon(Icons.restaurant_menu, color: Colors.green),
                    title: const Text("Dietary Preferences"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDietaryPrefs(context)),
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
          const Text("v3.0.0", style: TextStyle(color: Colors.grey)), // Removed Hive badge
          const SizedBox(height: 30),
        ]),
      ),
    );
  }
}
