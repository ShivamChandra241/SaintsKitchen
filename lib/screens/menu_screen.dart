import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:srm_kitchen/models/food_item.dart';
import 'package:srm_kitchen/providers/menu_provider.dart';
import 'package:srm_kitchen/providers/cart_provider.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  IconData getIconForFood(FoodItem item) {
    final n = item.name.toLowerCase();
    if (n.contains('pizza')) return Icons.local_pizza;
    if (n.contains('burger')) return Icons.lunch_dining;
    if (n.contains('biryani') || n.contains('rice')) return Icons.rice_bowl;
    if (n.contains('coffee') || n.contains('chai') || n.contains('tea')) {
      return Icons.local_cafe;
    }
    if (n.contains('ice cream') ||
        n.contains('cake') ||
        item.category == "Dessert") {
      return Icons.icecream;
    }
    if (!item.isVeg || n.contains('chicken') || n.contains('fish')) {
      return Icons.set_meal;
    }
    if (item.category == "Drinks") return Icons.local_drink;
    return Icons.restaurant;
  }

  void _showProductDetails(BuildContext context, FoodItem item) {
    FoodVariant? selectedVar =
        item.variants.isNotEmpty ? item.variants.first : null;
    int qty = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.80,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Image/Icon Area with Hero
              Center(
                child: Hero(
                  tag: 'food_icon_${item.id}',
                  child: Icon(
                    getIconForFood(item),
                    size: 100,
                    color: const Color(0xFF6200EA),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title & Heart
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(item.name,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  Consumer<MenuProvider>(
                    builder: (context, menu, _) => IconButton(
                      icon: Icon(
                          item.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.red, size: 30),
                      onPressed: () {
                        menu.toggleFavorite(item);
                        setSheetState(() {});
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // Metadata (Calorie, Rating, Popular)
              Row(
                children: [
                  if (item.isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(5)),
                      child: const Row(children: [
                        Icon(Icons.local_fire_department, size: 14, color: Colors.deepOrange),
                        SizedBox(width: 4),
                        Text("Popular", style: TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.bold))
                      ])
                    ),
                  if (item.rating > 0)
                    Row(children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      Text(" ${item.rating}", style: const TextStyle(fontWeight: FontWeight.bold))
                    ]),
                  const SizedBox(width: 10),
                  if (item.calories > 0)
                    Text("🔥 ${item.calories} kcal", style: const TextStyle(color: Colors.grey)),
                ],
              ),

              const SizedBox(height: 15),
              Text(item.description,
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 15,
                      height: 1.5)),
              const SizedBox(height: 20),

              if (item.variants.isNotEmpty) ...[
                const Text("Select Size/Variant:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 10,
                  children: item.variants
                      .map((v) => ChoiceChip(
                            label: Text("${v.name} - ₹${v.price}"),
                            selected: selectedVar == v,
                            onSelected: (b) =>
                                setSheetState(() => selectedVar = v),
                            selectedColor: const Color(0xFFFFD700),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Quantity",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      IconButton(
                          onPressed: () =>
                              qty > 1 ? setSheetState(() => qty--) : null,
                          icon: const Icon(Icons.remove)),
                      Text("$qty",
                          style:
                              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                          onPressed: () =>
                              setSheetState(() => qty++),
                          icon: const Icon(Icons.add)),
                    ]),
                  )
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6200EA),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    Provider.of<CartProvider>(context, listen: false)
                        .addToCart(item, selectedVar, qty);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${item.name} added to cart")),
                    );
                  },
                  child: Text(
                      "ADD TO CART - ₹${((selectedVar?.price ?? item.basePrice) * qty).toInt()}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => Provider.of<MenuProvider>(context, listen: false).setSearchQuery(v),
                    decoration: InputDecoration(
                      hintText: "Search items...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Consumer<MenuProvider>(
                  builder: (context, menu, _) => Row(
                    children: [
                      FilterChip(
                        label: const Text("Veg"),
                        selected: menu.showVegOnly,
                        onSelected: (val) => menu.toggleVegOnly(val),
                        selectedColor: Colors.green[100],
                        checkmarkColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Icon(Icons.favorite, size: 18, color: Colors.red),
                        selected: menu.showFavoritesOnly,
                        onSelected: (val) => menu.toggleFavoritesOnly(val),
                        selectedColor: Colors.red[100],
                        checkmarkColor: Colors.red,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Categories
          SizedBox(
            height: 40,
            child: Consumer<MenuProvider>(
              builder: (context, menu, _) => ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: menu.categories.length,
                itemBuilder: (context, index) {
                  final cat = menu.categories[index];
                  final isSelected = menu.selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => menu.setCategory(cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF6200EA) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected ? null : Border.all(color: Colors.grey),
                          gradient: isSelected ? const LinearGradient(colors: [Color(0xFF6200EA), Color(0xFF9900F0)]) : null
                        ),
                        child: Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700], fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Grid
          Expanded(
            child: Consumer<MenuProvider>(
              builder: (context, menu, _) => GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.70, // Taller for more info
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: menu.items.length,
                itemBuilder: (context, index) {
                  final item = menu.items[index];
                  return GestureDetector(
                    onTap: () => _showProductDetails(context, item),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Hero(
                                    tag: 'food_icon_${item.id}',
                                    child: Icon(getIconForFood(item),
                                        size: 50,
                                        color: const Color(0xFF6200EA)),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(item.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.variants.isNotEmpty
                                        ? "From ₹${item.variants.first.price}"
                                        : "₹${item.basePrice}",
                                    style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  if (item.rating > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(10)),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star, size: 12, color: Colors.deepOrange),
                                          Text(" ${item.rating}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepOrange))
                                        ],
                                      ),
                                    )
                                ]),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: item.isFavorite
                                ? const Icon(Icons.favorite,
                                    color: Colors.red, size: 20)
                                : const SizedBox(),
                          ),
                          if (item.isPopular)
                             Positioned(
                               top: 8,
                               left: 8,
                               child: Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                 decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                 child: const Text("HOT", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                               )
                             )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
