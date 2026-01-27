import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:srm_kitchen/services/database_service.dart';
import 'package:srm_kitchen/providers/user_provider.dart';
import 'package:srm_kitchen/providers/menu_provider.dart';
import 'package:srm_kitchen/providers/cart_provider.dart';
import 'package:srm_kitchen/theme/theme_provider.dart';
import 'package:srm_kitchen/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  runApp(const SRMKitchenApp());
}

class SRMKitchenApp extends StatelessWidget {
  const SRMKitchenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'SRM Kitchen',
            debugShowCheckedModeBanner: false,
            themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6200EA),
                secondary: const Color(0xFFFFD700),
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: const Color(0xFFF8F9FE),
              textTheme: GoogleFonts.poppinsTextTheme(),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6200EA),
                secondary: const Color(0xFFFFD700),
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: const Color(0xFF121212),
              textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
