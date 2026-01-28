import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/database_service.dart';

class MenuProvider extends ChangeNotifier {
  List<FoodItem> _fullMenu = [];
  List<FoodItem> _filteredMenu = [];

  String _searchQuery = "";
  String _selectedCategory = "All";
  bool _showVegOnly = false;

  List<String> get categories => ["All", "Java Green", "Tech Park", "University Building", "Main Canteen", "Dessert"];

  List<FoodItem> get items => _filteredMenu;
  String get selectedCategory => _selectedCategory;
  bool get showVegOnly => _showVegOnly;

  MenuProvider() {
    _initMenu();
    _loadFavorites();
  }

  void _initMenu() {
    _fullMenu = [
      // JAVA GREEN (Popular Spot)
      FoodItem("101", "Java Green Combo", "Java Green", 120, true,
          "2 Aloo Paratha, Curd, Pickle & Mint Mojito.",
          variants: [FoodVariant("Mini", 90), FoodVariant("Full", 120)]),
      FoodItem("102", "Chilly Cheese Toast", "Java Green", 60, true,
          "Spicy cheese toast grilled to perfection."),
      FoodItem("103", "Cold Coffee with Ice Cream", "Java Green", 80, true,
          "The legendary JG cold coffee."),
      FoodItem("104", "Chicken Schezwan Fried Rice", "Java Green", 140, false,
          "Spicy fried rice with chicken chunks."),

      // TECH PARK (Quick Bites)
      FoodItem("201", "TP Sandwich", "Tech Park", 50, true,
          "Bombay style grilled sandwich."),
      FoodItem("202", "Chicken Puff", "Tech Park", 30, false,
          "Flaky pastry filled with spicy chicken."),
      FoodItem("203", "Samosa Chaat", "Tech Park", 45, true,
          "Samosa crushed with chole, yogurt and chutneys."),
      FoodItem("204", "Egg Maggi", "Tech Park", 50, false,
          "Masala Maggi with scrambled eggs."),

      // UNIVERSITY BUILDING (UB)
      FoodItem("301", "UB Thali", "University Building", 100, true,
          "Rice, Sambar, Rasam, Poriyal, Curd & Pickle."),
      FoodItem("302", "Chicken Biryani (UB Special)", "University Building", 160, false,
          "Authentic dum biryani served with raita."),
      FoodItem("303", "Gobi Manchurian", "University Building", 90, true,
          "Crispy cauliflower tossed in manchurian sauce."),

      // MAIN CANTEEN
      FoodItem("401", "Masala Dosa", "Main Canteen", 60, true,
          "Crispy dosa with potato filling and chutney."),
      FoodItem("402", "Chole Bhature", "Main Canteen", 80, true,
          "Classic North Indian breakfast."),
      FoodItem("403", "Fresh Juice", "Main Canteen", 40, true,
          "Watermelon / Orange / Pineapple.",
          variants: [FoodVariant("Small", 40), FoodVariant("Large", 60)]),

      // DESSERTS
      FoodItem("501", "Sizzling Brownie", "Dessert", 110, true,
          "Hot brownie on sizzling plate with ice cream."),
      FoodItem("502", "Gulab Jamun", "Dessert", 40, true,
          "2 pcs hot gulab jamun."),
      FoodItem("503", "SRM Special Falooda", "Dessert", 100, true,
          "Loaded with jelly, fruits, nuts and ice cream."),
    ];
    _applyFilters();
  }

  void _loadFavorites() {
    final favIds = DatabaseService.favorites.values.toSet();
    for (var item in _fullMenu) {
      if (favIds.contains(item.id)) {
        item.isFavorite = true;
      }
    }
    notifyListeners();
  }

  void toggleFavorite(FoodItem item) {
    item.isFavorite = !item.isFavorite;
    if (item.isFavorite) {
      DatabaseService.favorites.add(item.id);
    } else {
      final Map<dynamic, String> map = DatabaseService.favorites.toMap().cast<dynamic, String>();
      dynamic keyToDelete;
      map.forEach((key, value) {
        if (value == item.id) keyToDelete = key;
      });
      if (keyToDelete != null) DatabaseService.favorites.delete(keyToDelete);
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void toggleVegOnly(bool value) {
    _showVegOnly = value;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredMenu = _fullMenu.where((item) {
      final matchesCat = _selectedCategory == "All" || item.category == _selectedCategory;
      final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesVeg = !_showVegOnly || item.isVeg;
      return matchesCat && matchesSearch && matchesVeg;
    }).toList();
    notifyListeners();
  }
}
