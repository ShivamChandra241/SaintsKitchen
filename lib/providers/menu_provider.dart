import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/database_service.dart';

class MenuProvider extends ChangeNotifier {
  List<FoodItem> _fullMenu = [];
  List<FoodItem> _filteredMenu = [];

  String _searchQuery = "";
  String _selectedCategory = "All";
  bool _showVegOnly = false;
  bool _showFavoritesOnly = false;

  List<String> get categories => ["All", "Express", "Java Green", "Tech Park", "University Building", "Main Canteen", "Dessert"];

  List<FoodItem> get items => _filteredMenu;
  String get selectedCategory => _selectedCategory;
  bool get showVegOnly => _showVegOnly;
  bool get showFavoritesOnly => _showFavoritesOnly;

  MenuProvider() {
    _initMenu();
    _loadFavorites();
  }

  void _initMenu() {
    _fullMenu = [
      // EXPRESS (Ready in 2 mins)
      FoodItem("EX01", "Veg Puff", "Express", 25, true, "Flaky puff pastry with spicy veg filling. Ready in 2 mins.",
        calories: 250, rating: 4.2, isPopular: true, imageUrl: "https://images.unsplash.com/photo-1626082929543-5bab0f006c42?auto=format&fit=crop&w=500&q=60"),
      FoodItem("EX02", "Chicken Puff", "Express", 35, false, "Golden crispy puff with chicken masala. Grab & Go.",
        calories: 300, rating: 4.5, isPopular: true, imageUrl: "https://images.unsplash.com/photo-1606728035253-49e8a23146de?auto=format&fit=crop&w=500&q=60"),
      FoodItem("EX03", "Samosa (2pcs)", "Express", 30, true, "Hot and crispy samosas with mint chutney.",
        calories: 200, rating: 4.6, isPopular: true, imageUrl: "https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=500&q=60"),
      FoodItem("EX04", "Egg Puff", "Express", 30, false, "Spicy egg masala inside crispy puff.",
        calories: 280, rating: 4.3, imageUrl: "https://images.unsplash.com/photo-1626082927389-d52d83e3016c?auto=format&fit=crop&w=500&q=60"),
      FoodItem("EX05", "Cream Bun", "Express", 20, true, "Soft bun filled with fresh cream.",
        calories: 150, rating: 4.0, imageUrl: "https://images.unsplash.com/photo-1603532648955-039310d9ed75?auto=format&fit=crop&w=500&q=60"),
      FoodItem("EX06", "Chocolate Donut", "Express", 40, true, "Glazed chocolate donut.",
        calories: 350, rating: 4.7, imageUrl: "https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&w=500&q=60"),

      // JAVA GREEN (Popular Spot)
      FoodItem("JG01", "Java Green Combo", "Java Green", 120, true, "2 Aloo Paratha, Curd, Pickle & Mint Mojito.",
        variants: [FoodVariant("Mini", 90), FoodVariant("Full", 120)], calories: 800, rating: 4.8, isPopular: true, imageUrl: "https://images.unsplash.com/photo-1626082928073-631d8c1c49b0?auto=format&fit=crop&w=500&q=60"), // Mock Paratha
      FoodItem("JG02", "Chilly Cheese Toast", "Java Green", 60, true, "Spicy cheese toast grilled to perfection.",
        calories: 300, rating: 4.4, imageUrl: "https://images.unsplash.com/photo-1584776296944-ab6fb985cc9d?auto=format&fit=crop&w=500&q=60"),
      FoodItem("JG03", "Cold Coffee with Ice Cream", "Java Green", 80, true, "The legendary JG cold coffee.",
        calories: 400, rating: 4.9, isPopular: true, imageUrl: "https://images.unsplash.com/photo-1572490122747-3968b75cc699?auto=format&fit=crop&w=500&q=60"),
      FoodItem("JG04", "Chicken Schezwan Fried Rice", "Java Green", 140, false, "Spicy fried rice with chicken chunks.",
        calories: 600, rating: 4.5, imageUrl: "https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=500&q=60"),
      FoodItem("JG05", "Paneer Butter Masala", "Java Green", 150, true, "Rich creamy gravy with cottage cheese.",
        calories: 550, rating: 4.6, imageUrl: "https://images.unsplash.com/photo-1631452180519-c014fe946bc7?auto=format&fit=crop&w=500&q=60"),
      FoodItem("JG06", "Butter Naan", "Java Green", 40, true, "Soft tandoori bread with butter.",
        calories: 200, rating: 4.3, imageUrl: "https://images.unsplash.com/photo-1626074353765-517a681e40be?auto=format&fit=crop&w=500&q=60"),
      FoodItem("JG07", "Chicken 65", "Java Green", 130, false, "Spicy deep fried chicken starter.",
        calories: 450, rating: 4.7, imageUrl: "https://images.unsplash.com/photo-1610057099443-fde8c4d50f91?auto=format&fit=crop&w=500&q=60"),
      FoodItem("JG08", "Veg Noodles", "Java Green", 100, true, "Hakka style noodles with veggies.",
        calories: 400, rating: 4.2, imageUrl: "https://images.unsplash.com/photo-1612929633738-8fe44f7ec841?auto=format&fit=crop&w=500&q=60"),

      // TECH PARK (Quick Bites)
      FoodItem("TP01", "TP Sandwich", "Tech Park", 50, true, "Bombay style grilled sandwich.",
        calories: 300, rating: 4.1, imageUrl: "https://images.unsplash.com/photo-1528735602780-2552fd46c7af?auto=format&fit=crop&w=500&q=60"),
      FoodItem("TP02", "Samosa Chaat", "Tech Park", 45, true, "Samosa crushed with chole, yogurt and chutneys.",
        calories: 350, rating: 4.5, isPopular: true, imageUrl: "https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=500&q=60"),
      FoodItem("TP03", "Egg Maggi", "Tech Park", 50, false, "Masala Maggi with scrambled eggs.",
        calories: 320, rating: 4.6, imageUrl: "https://images.unsplash.com/photo-1612929633738-8fe44f7ec841?auto=format&fit=crop&w=500&q=60"),
      FoodItem("TP04", "Veg Momos (6pcs)", "Tech Park", 60, true, "Steamed dumplings served with spicy sauce.",
        calories: 200, rating: 4.3, imageUrl: "https://images.unsplash.com/photo-1496116218417-1a781b1c416c?auto=format&fit=crop&w=500&q=60"),
      FoodItem("TP05", "Chicken Momos (6pcs)", "Tech Park", 80, false, "Juicy chicken dumplings.",
        calories: 250, rating: 4.5, imageUrl: "https://images.unsplash.com/photo-1589302168068-964664d93dc0?auto=format&fit=crop&w=500&q=60"),
      FoodItem("TP06", "Peri Peri Fries", "Tech Park", 70, true, "Crispy fries tossed in peri peri spice.",
        calories: 350, rating: 4.4, imageUrl: "https://images.unsplash.com/photo-1630384060421-a4323ce5663d?auto=format&fit=crop&w=500&q=60"),
      FoodItem("TP07", "Vada Pav", "Tech Park", 25, true, "Mumbai's favorite burger.",
        calories: 280, rating: 4.2, imageUrl: "https://images.unsplash.com/photo-1631452180546-991b10705d0e?auto=format&fit=crop&w=500&q=60"),

      // UNIVERSITY BUILDING (UB)
      FoodItem("UB01", "UB Thali", "University Building", 100, true, "Rice, Sambar, Rasam, Poriyal, Curd & Pickle.",
        calories: 700, rating: 4.4, imageUrl: "https://images.unsplash.com/photo-1626082927827-048754128030?auto=format&fit=crop&w=500&q=60"),
      FoodItem("UB02", "Chicken Biryani", "University Building", 160, false, "Authentic dum biryani served with raita.",
        calories: 800, rating: 4.8, isPopular: true, imageUrl: "https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&w=500&q=60"),
      FoodItem("UB03", "Gobi Manchurian", "University Building", 90, true, "Crispy cauliflower tossed in manchurian sauce.",
        calories: 350, rating: 4.3, imageUrl: "https://images.unsplash.com/photo-1625938146369-adc83368bda7?auto=format&fit=crop&w=500&q=60"),
      FoodItem("UB04", "Curd Rice", "University Building", 60, true, "Comfort food with pomegranate seeds.",
        calories: 300, rating: 4.5, imageUrl: "https://images.unsplash.com/photo-1606756858546-d2435f9211d1?auto=format&fit=crop&w=500&q=60"), // Mock
      FoodItem("UB05", "Podium Idli", "University Building", 50, true, "Mini idlis tossed in spicy gun powder.",
        calories: 250, rating: 4.2, imageUrl: "https://images.unsplash.com/photo-1589301760576-41f47391121f?auto=format&fit=crop&w=500&q=60"),
      FoodItem("UB06", "Chicken Kothu Parotta", "University Building", 120, false, "Minced parotta with spicy chicken curry.",
        calories: 650, rating: 4.7, imageUrl: "https://images.unsplash.com/photo-1618485265551-7c98b8242c75?auto=format&fit=crop&w=500&q=60"), // Mock

      // MAIN CANTEEN
      FoodItem("MC01", "Masala Dosa", "Main Canteen", 60, true, "Crispy dosa with potato filling and chutney.",
        calories: 350, rating: 4.6, imageUrl: "https://images.unsplash.com/photo-1630384060421-a4323ce5663d?auto=format&fit=crop&w=500&q=60"), // Mock
      FoodItem("MC02", "Chole Bhature", "Main Canteen", 80, true, "Classic North Indian breakfast.",
        calories: 600, rating: 4.5, imageUrl: "https://images.unsplash.com/photo-1626082928073-631d8c1c49b0?auto=format&fit=crop&w=500&q=60"),
      FoodItem("MC03", "Fresh Juice", "Main Canteen", 40, true, "Watermelon / Orange / Pineapple.", variants: [FoodVariant("Small", 40), FoodVariant("Large", 60)],
        calories: 150, rating: 4.4, imageUrl: "https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&w=500&q=60"),
      FoodItem("MC04", "Meals", "Main Canteen", 90, true, "Full South Indian meals.",
        calories: 750, rating: 4.3, imageUrl: "https://images.unsplash.com/photo-1626082927827-048754128030?auto=format&fit=crop&w=500&q=60"),
      FoodItem("MC05", "Chapati Kurma", "Main Canteen", 50, true, "3 Chapatis with veg kurma.",
        calories: 400, rating: 4.1, imageUrl: "https://images.unsplash.com/photo-1565557623262-b51c2513a641?auto=format&fit=crop&w=500&q=60"),
      FoodItem("MC06", "Omelette", "Main Canteen", 30, false, "Double egg omelette with onions.",
        calories: 200, rating: 4.2, imageUrl: "https://images.unsplash.com/photo-1510693206972-df098062cb71?auto=format&fit=crop&w=500&q=60"),
      FoodItem("MC07", "Parotta Salna", "Main Canteen", 45, true, "2 Parottas with spicy salna.",
        calories: 500, rating: 4.0, imageUrl: "https://images.unsplash.com/photo-1606491956689-2ea866880c84?auto=format&fit=crop&w=500&q=60"), // Mock

      // DESSERTS
      FoodItem("DS01", "Sizzling Brownie", "Dessert", 110, true, "Hot brownie on sizzling plate with ice cream.",
        calories: 600, rating: 4.9, isPopular: true, imageUrl: "https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&w=500&q=60"),
      FoodItem("DS02", "Gulab Jamun", "Dessert", 40, true, "2 pcs hot gulab jamun.",
        calories: 300, rating: 4.5, imageUrl: "https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=500&q=60"), // Mock
      FoodItem("DS03", "SRM Special Falooda", "Dessert", 100, true, "Loaded with jelly, fruits, nuts and ice cream.",
        calories: 500, rating: 4.8, imageUrl: "https://images.unsplash.com/photo-1579954115563-e72bf1381629?auto=format&fit=crop&w=500&q=60"),
      FoodItem("DS04", "Ice Cream", "Dessert", 40, true, "Vanilla / Strawberry / Chocolate.",
        calories: 200, rating: 4.3, imageUrl: "https://images.unsplash.com/photo-1560008581-09826d1de69e?auto=format&fit=crop&w=500&q=60"),
      FoodItem("DS05", "Fruit Salad", "Dessert", 60, true, "Fresh cut seasonal fruits.",
        calories: 150, rating: 4.4, imageUrl: "https://images.unsplash.com/photo-1519996529931-28324d1a630e?auto=format&fit=crop&w=500&q=60"),
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

  void toggleFavoritesOnly(bool value) {
    _showFavoritesOnly = value;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredMenu = _fullMenu.where((item) {
      final matchesCat = _selectedCategory == "All" || item.category == _selectedCategory;
      final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesVeg = !_showVegOnly || item.isVeg;
      final matchesFav = !_showFavoritesOnly || item.isFavorite;
      return matchesCat && matchesSearch && matchesVeg && matchesFav;
    }).toList();
    notifyListeners();
  }
}
