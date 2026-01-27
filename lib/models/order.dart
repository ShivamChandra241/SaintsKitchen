import 'package:hive/hive.dart';
import 'cart_item.dart';

class Order {
  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double paid;
  final DateTime timestamp;
  int? rating;

  Order(
    this.id,
    this.items,
    this.subtotal,
    this.discount,
    this.paid,
    this.timestamp, {
    this.rating,
  });
}

class OrderAdapter extends TypeAdapter<Order> {
  @override
  final int typeId = 4;

  @override
  Order read(BinaryReader reader) {
    return Order(
      reader.readString(), // id
      (reader.readList()).cast<CartItem>(), // items
      reader.readDouble(), // subtotal
      reader.readDouble(), // discount
      reader.readDouble(), // paid
      DateTime.fromMillisecondsSinceEpoch(reader.readInt()), // timestamp
      rating: reader.readBool() ? reader.readInt() : null,
    );
  }

  @override
  void write(BinaryWriter writer, Order obj) {
    writer.writeString(obj.id);
    writer.writeList(obj.items);
    writer.writeDouble(obj.subtotal);
    writer.writeDouble(obj.discount);
    writer.writeDouble(obj.paid);
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
    writer.writeBool(obj.rating != null);
    if (obj.rating != null) {
      writer.writeInt(obj.rating!);
    }
  }
}
