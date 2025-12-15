// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spend_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SpendAdapter extends TypeAdapter<Spend> {
  @override
  final int typeId = 2;

  @override
  Spend read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Spend(
      date: fields[0] as DateTime,
      amount: fields[1] as int,
      description: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Spend obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpendAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
