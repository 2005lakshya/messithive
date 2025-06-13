// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_card.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MenuCardAdapter extends TypeAdapter<MenuCard> {
  @override
  final int typeId = 0;

  @override
  MenuCard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MenuCard(
      title: fields[0] as String,
      time: fields[1] as String,
      food: fields[2] as String,
      beverages: fields[3] as String,
      imagePath: fields[4] as String,
      isFavorite: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MenuCard obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.time)
      ..writeByte(2)
      ..write(obj.food)
      ..writeByte(3)
      ..write(obj.beverages)
      ..writeByte(4)
      ..write(obj.imagePath)
      ..writeByte(5)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuCardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
