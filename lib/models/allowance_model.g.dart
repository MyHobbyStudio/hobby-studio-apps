// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allowance_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AllowanceAdapter extends TypeAdapter<Allowance> {
  @override
  final int typeId = 1;

  @override
  Allowance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Allowance(
      date: fields[0] as DateTime,
      amount: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Allowance obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.amount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AllowanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
