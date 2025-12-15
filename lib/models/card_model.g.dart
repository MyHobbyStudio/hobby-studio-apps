// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CardModelAdapter extends TypeAdapter<CardModel> {
  @override
  final int typeId = 0;

  @override
  CardModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CardModel(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      imagePath: fields[3] as String?,
      price: fields[4] as int?,
      date: fields[7] as DateTime?,
      tags: (fields[8] as List?)?.cast<String>(),
    )
      .._isWishList = fields[5] as bool?
      ..source = fields[6] as String?;
  }

  @override
  void write(BinaryWriter writer, CardModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.imagePath)
      ..writeByte(4)
      ..write(obj.price)
      ..writeByte(5)
      ..write(obj._isWishList)
      ..writeByte(6)
      ..write(obj.source)
      ..writeByte(7)
      ..write(obj.date)
      ..writeByte(8)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
