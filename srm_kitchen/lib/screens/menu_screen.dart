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
          height: MediaQuery.of(context).size.height * 0.75,
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
              Center(
                child: Icon(
                  getIconForFood(item),
                  size: 80,
                  color: const Color(0xFF6200EA),
                ),
              ),
              const SizedBox(height: 20),
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
                          color: Colors.red),
                      onPressed: () {
                        menu.toggleFavorite(item);
                        setSheetState(() {}); // update sheet UI
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
                              const TextStyle(fontWeight: FontWeight.bold)),
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
                      foregroundColor: Colors.white),
                  onPressed: () {
                    Provider.of<CartProvider>(context, listen: false)
                        .addToCart(item, selectedVar, qty);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${item.name} added to cart")),
                    );
                  },
                  child: Text(
                      "ADD TO CART - ₹${((selectedVar?.price ?? item.basePrice) * qty).toInt()}"),
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
                      // fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Consumer<MenuProvider>(
                  builder: (context, menu, _) => FilterChip(
                    label: const Text("Veg"),
                    selected: menu.showVegOnly,
                    onSelected: (val) => menu.toggleVegOnly(val),
                    selectedColor: Colors.green[100],
                    checkmarkColor: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 50,
            child: Consumer<MenuProvider>(
              builder: (context, menu, _) => ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: menu.categories.length,
                itemBuilder: (context, index) {
                  final cat = menu.categories[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: menu.selectedCategory == cat,
                      onSelected: (b) => menu.setCategory(cat),
                      selectedColor: const Color(0xFF6200EA),
                      labelStyle: TextStyle(
                          color: menu.selectedCategory == cat
                              ? Colors.white
                              : null), // Adapt to theme
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Consumer<MenuProvider>(
              builder: (context, menu, _) => GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
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
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 5)
                        ],
                      ),
                      child: Stack(
                        children: [
                          Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(getIconForFood(item),
                                    size: 45,
                                    color: const Color(0xFF6200EA)),
                                const SizedBox(height: 10),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(item.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                Text(
                                  item.variants.isNotEmpty
                                      ? "From ₹${item.variants.first.price}"
                                      : "₹${item.basePrice}",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ]),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: item.isFavorite
                                ? const Icon(Icons.favorite,
                                    color: Colors.red, size: 20)
                                : const SizedBox(),
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
