import 'package:flutter/material.dart';
import 'package:srm_kitchen/services/database_service.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() {
    _isDark = DatabaseService.user.get('isDark', defaultValue: false);
    notifyListeners();
  }

  void toggleTheme() {
    _isDark = !_isDark;
    DatabaseService.user.put('isDark', _isDark);
    notifyListeners();
  }

  // Gradient Colors
  LinearGradient get primaryGradient => _isDark
      ? const LinearGradient(colors: [Color(0xFF6200EA), Color(0xFF651FFF)])
      : const LinearGradient(colors: [Color(0xFF6200EA), Color(0xFF9900F0)]);

  LinearGradient get cardGradient => _isDark
      ? const LinearGradient(colors: [Color(0xFF2D2D2D), Color(0xFF1E1E1E)])
      : const LinearGradient(colors: [Colors.white, Color(0xFFF0F0F0)]);
}
