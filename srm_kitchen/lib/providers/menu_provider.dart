import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/database_service.dart';

class MenuProvider extends ChangeNotifier {
  List<FoodItem> _fullMenu = [];
  List<FoodItem> _filteredMenu = [];

  String _searchQuery = "";
  String _selectedCategory = "All";
  bool _showVegOnly = false;

  List<String> get categories => ["All", "Thali", "Meals", "Snacks", "Drinks", "Dessert"];

  List<FoodItem> get items => _filteredMenu;
  String get selectedCategory => _selectedCategory;
  bool get showVegOnly => _showVegOnly;

  MenuProvider() {
    _initMenu();
    _loadFavorites();
  }

  void _initMenu() {
    _fullMenu = [
      // THALI
      FoodItem("101", "Chole Bhature Thali", "Thali", 120, true,
          "2 Fluffy Bhature, Spicy Chole, Pickle, Salad & Lassi.",
          variants: [FoodVariant("Half", 80), FoodVariant("Full", 120)]),
      FoodItem("102", "Rajma Chawal Thali", "Thali", 110, true,
          "Home-style Rajma, Basmati Rice, Raita & Papad.",
          variants: [FoodVariant("Mini", 70), FoodVariant("Full", 110)]),
      FoodItem("103", "Chicken Curry Thali", "Thali", 160, false,
          "Spicy Chicken Curry, 2 Rotis, Jeera Rice, Salad.",
          variants: [FoodVariant("Standard", 160), FoodVariant("Deluxe", 200)]),
      FoodItem("104", "South Indian Thali", "Thali", 100, true,
          "Idli, Vada, Mini Dosa, Sambar & Chutneys."),
      FoodItem("105", "Veg Deluxe Thali", "Thali", 150, true,
          "Paneer Butter Masala, Dal Makhani, 2 Naan, Rice & Sweet."),
      FoodItem("106", "Fish Curry Thali", "Thali", 180, false,
          "Coastal style Fish Curry, Steamed Rice, Sol Kadhi."),
      FoodItem("107", "Egg Curry Thali", "Thali", 130, false,
          "2 Egg Curry, 3 Chapatis, Rice, Salad."),
      FoodItem("108", "Dal Baati Churma", "Thali", 140, true,
          "Traditional Rajasthani Dal Baati with sweet Churma."),

      // MEALS
      FoodItem("201", "Classic Burger", "Meals", 60, false,
          "Grilled patty, lettuce, tomato & house sauce."),
      FoodItem("202", "Veggie Burger", "Meals", 50, true,
          "Crispy potato & peas patty with mayo."),
      FoodItem("203", "Cheese Pizza", "Meals", 99, true,
          "Mozzarella cheese burst with basil.",
          variants: [FoodVariant("Regular", 99), FoodVariant("Large", 199)]),
      FoodItem("204", "Chicken Pizza", "Meals", 149, false,
          "BBQ Chicken chunks, onions and paprika.",
          variants: [FoodVariant("Regular", 149), FoodVariant("Large", 249)]),
      FoodItem("205", "Veg Biryani", "Meals", 130, true,
          "Aromatic basmati rice cooked with fresh veggies."),
      FoodItem("206", "Chicken Biryani", "Meals", 180, false,
          "Hyderabadi style dum biryani with raita."),
      FoodItem("207", "Chicken Wrap", "Meals", 90, false,
          "Spicy chicken strips in a soft tortilla wrap."),
      FoodItem("208", "Paneer Tikka Roll", "Meals", 85, true,
          "Char-grilled paneer cubes in roomali roti."),
      FoodItem("209", "Pasta Alfredo", "Meals", 110, true,
          "White sauce penne pasta with corn and olives."),
      FoodItem("210", "Pasta Arrabbiata", "Meals", 110, true,
          "Red sauce spicy pasta with basil."),
      FoodItem("211", "Fried Rice", "Meals", 90, true,
          "Indo-Chinese style veg fried rice."),
      FoodItem("212", "Hakka Noodles", "Meals", 90, true,
          "Stir-fried noodles with crunchy vegetables."),

      // SNACKS
      FoodItem("301", "Peri Peri Fries", "Snacks", 60, true,
          "Crispy fries tossed in spicy peri peri mix.",
          variants: [FoodVariant("Small", 40), FoodVariant("Large", 60)]),
      FoodItem("302", "Veg Sandwich", "Snacks", 45, true,
          "Grilled sandwich with cucumber & chutney."),
      FoodItem("303", "Chicken Nuggets", "Snacks", 90, false,
          "6 pieces of golden fried chicken nuggets."),
      FoodItem("304", "Samosa (2pcs)", "Snacks", 30, true,
          "Hot potato stuffed samosas with mint chutney."),
      FoodItem("305", "Garlic Bread", "Snacks", 70, true,
          "Toasted baguette with garlic butter."),
      FoodItem("306", "Vada Pav", "Snacks", 25, true,
          "Mumbai style spicy potato slider."),
      FoodItem("307", "Chicken Popcorn", "Snacks", 100, false,
          "Bite sized crunchy fried chicken."),
      FoodItem("308", "Paneer 65", "Snacks", 110, true,
          "Spicy deep fried paneer cubes."),
      FoodItem("309", "Nachos with Salsa", "Snacks", 80, true,
          "Crispy chips with tangy salsa dip."),
      FoodItem("310", "Spring Rolls", "Snacks", 70, true,
          "Crispy fried rolls stuffed with veggies."),

      // DRINKS
      FoodItem("401", "Coca Cola", "Drinks", 25, true, "Chilled fizzy cola.",
          variants: [FoodVariant("Can", 25), FoodVariant("Bottle", 40)]),
      FoodItem("402", "Cold Coffee", "Drinks", 60, true,
          "Creamy blended coffee with ice cream."),
      FoodItem("403", "Mango Lassi", "Drinks", 50, true,
          "Thick yogurt drink with fresh mango pulp."),
      FoodItem("404", "Masala Chai", "Drinks", 20, true,
          "Hot tea infused with cardamom & ginger."),
      FoodItem("405", "Mint Mojito", "Drinks", 70, true,
          "Refreshing lime and mint virgin mojito."),
      FoodItem("406", "Orange Juice", "Drinks", 60, true,
          "Freshly squeezed orange juice."),
      FoodItem("407", "Chocolate Milkshake", "Drinks", 80, true,
          "Thick chocolate shake with brownie crumbs."),
      FoodItem("408", "Lemon Iced Tea", "Drinks", 50, true,
          "Chilled tea with a hint of lemon."),
      FoodItem("409", "Water Bottle", "Drinks", 20, true,
          "1 Litre mineral water bottle."),

      // DESSERTS
      FoodItem("501", "Choco Lava Cake", "Dessert", 80, true,
          "Warm chocolate cake with a gooey center."),
      FoodItem("502", "Gulab Jamun (2pcs)", "Dessert", 40, true,
          "Fried dough balls soaked in sugar syrup."),
      FoodItem("503", "Ice Cream Scoop", "Dessert", 50, true,
          "Vanilla, Strawberry or Chocolate scoop."),
      FoodItem("504", "Brownie with Ice Cream", "Dessert", 100, true,
          "Walnut brownie topped with vanilla ice cream."),
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
      DatabaseService.favorites.put(item.id, item.id);
    } else {
      // Try fast deletion first (Key == ID)
      if (DatabaseService.favorites.containsKey(item.id)) {
        DatabaseService.favorites.delete(item.id);
      } else {
        // Fallback for legacy favorites (Key != ID)
        final Map<dynamic, String> map = DatabaseService.favorites.toMap().cast<dynamic, String>();
        dynamic keyToDelete;
        map.forEach((key, value) {
          if (value == item.id) keyToDelete = key;
        });
        if (keyToDelete != null) DatabaseService.favorites.delete(keyToDelete);
      }
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
