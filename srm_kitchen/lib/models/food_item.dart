import 'package:hive/hive.dart';

class FoodVariant {
  final String name;
  final double price;

  FoodVariant(this.name, this.price);

  Map<String, dynamic> toJson() => {'name': name, 'price': price};
  factory FoodVariant.fromJson(Map<String, dynamic> json) =>
      FoodVariant(json['name'], (json['price'] as num).toDouble());
}

class FoodItem {
  final String id;
  final String name;
  final String category;
  final double basePrice;
  final bool isVeg;
  final String description;
  final List<FoodVariant> variants;
  bool isFavorite; // New field

  FoodItem(
    this.id,
    this.name,
    this.category,
    this.basePrice,
    this.isVeg,
    this.description, {
    this.variants = const [],
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'basePrice': basePrice,
        'isVeg': isVeg,
        'description': description,
        'variants': variants.map((v) => v.toJson()).toList(),
        'isFavorite': isFavorite,
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        json['id'],
        json['name'],
        json['category'],
        (json['basePrice'] as num).toDouble(),
        json['isVeg'],
        json['description'],
        variants: (json['variants'] as List?)
                ?.map((v) => FoodVariant.fromJson(v))
                .toList() ??
            [],
        isFavorite: json['isFavorite'] ?? false,
      );
}

// Hive Adapters
class FoodVariantAdapter extends TypeAdapter<FoodVariant> {
  @override
  final int typeId = 0;

  @override
  FoodVariant read(BinaryReader reader) {
    return FoodVariant(reader.readString(), reader.readDouble());
  }

  @override
  void write(BinaryWriter writer, FoodVariant obj) {
    writer.writeString(obj.name);
    writer.writeDouble(obj.price);
  }
}

class FoodItemAdapter extends TypeAdapter<FoodItem> {
  @override
  final int typeId = 1;

  @override
  FoodItem read(BinaryReader reader) {
    return FoodItem(
      reader.readString(), // id
      reader.readString(), // name
      reader.readString(), // category
      reader.readDouble(), // basePrice
      reader.readBool(),   // isVeg
      reader.readString(), // description
      variants: (reader.readList()).cast<FoodVariant>(),
      isFavorite: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, FoodItem obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.category);
    writer.writeDouble(obj.basePrice);
    writer.writeBool(obj.isVeg);
    writer.writeString(obj.description);
    writer.writeList(obj.variants);
    writer.writeBool(obj.isFavorite);
  }
}
