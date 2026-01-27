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
}
