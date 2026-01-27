import 'package:hive/hive.dart';
import 'food_item.dart';

class CartItem {
  final FoodItem item;
  FoodVariant? selectedVariant;
  int quantity;

  CartItem(this.item, this.quantity, {this.selectedVariant});

  double get unitPrice =>
      (selectedVariant?.price ?? item.basePrice).toDouble();
  double get totalPrice => unitPrice * quantity;
  String get displayName =>
      selectedVariant != null ? "${item.name} (${selectedVariant!.name})" : item.name;
}

class CartItemAdapter extends TypeAdapter<CartItem> {
  @override
  final int typeId = 2;

  @override
  CartItem read(BinaryReader reader) {
    return CartItem(
      reader.read() as FoodItem, // item
      reader.readInt(),          // quantity
      selectedVariant: reader.readBool() ? reader.read() as FoodVariant : null,
    );
  }

  @override
  void write(BinaryWriter writer, CartItem obj) {
    writer.write(obj.item);
    writer.writeInt(obj.quantity);
    writer.writeBool(obj.selectedVariant != null);
    if (obj.selectedVariant != null) {
      writer.write(obj.selectedVariant);
    }
  }
}
