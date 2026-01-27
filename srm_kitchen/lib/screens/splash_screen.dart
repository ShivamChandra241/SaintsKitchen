import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:srm_kitchen/providers/user_provider.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), _checkLogin);
  }

  void _checkLogin() {
    final user = Provider.of<UserProvider>(context, listen: false);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            user.isLoggedIn ? const MainScreen() : const LoginScreen(),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6200EA), Color(0xFF3700B3)],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 20,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: Color(0xFF6200EA),
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "SAINTS KITCHEN",
                    style: GoogleFonts.bebasNeue(
                      fontSize: 38,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Saints Row III School",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(color: Colors.white),
                ],
              ),
            ),
            const Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "v1.0.0 • Powered by Hive",
                  style: TextStyle(color: Colors.white30, fontSize: 10),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
