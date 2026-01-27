import 'package:hive/hive.dart';

class WalletTransaction {
  final String id;
  final String title;
  final double amount;
  final bool isCredit;
  final String method;
  final DateTime date;
  final String? meta;

  WalletTransaction(
    this.id,
    this.title,
    this.amount,
    this.isCredit,
    this.method,
    this.date, {
    this.meta,
  });
}

class WalletTransactionAdapter extends TypeAdapter<WalletTransaction> {
  @override
  final int typeId = 3;

  @override
  WalletTransaction read(BinaryReader reader) {
    return WalletTransaction(
      reader.readString(), // id
      reader.readString(), // title
      reader.readDouble(), // amount
      reader.readBool(),   // isCredit
      reader.readString(), // method
      DateTime.fromMillisecondsSinceEpoch(reader.readInt()), // date
      meta: reader.readBool() ? reader.readString() : null,
    );
  }

  @override
  void write(BinaryWriter writer, WalletTransaction obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeDouble(obj.amount);
    writer.writeBool(obj.isCredit);
    writer.writeString(obj.method);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeBool(obj.meta != null);
    if (obj.meta != null) {
      writer.writeString(obj.meta!);
    }
  }
}
