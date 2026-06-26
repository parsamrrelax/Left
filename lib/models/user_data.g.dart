// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserDataAdapter extends TypeAdapter<UserData> {
  @override
  final int typeId = 0;

  @override
  UserData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserData(
      birthday: fields[0] as DateTime?,
      expectedLifespan: fields[1] as int?,
      importantDates: (fields[2] as List).cast<ImportantDate>(),
      hiddenScreens: (fields[3] as List?)?.cast<String>(),
      useDynamicTheme: fields[4] as bool?,
      fontFamily: fields[5] as String?,
      useAmoledTheme: fields[6] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, UserData obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.birthday)
      ..writeByte(1)
      ..write(obj.expectedLifespan)
      ..writeByte(2)
      ..write(obj.importantDates)
      ..writeByte(3)
      ..write(obj.hiddenScreens)
      ..writeByte(4)
      ..write(obj.useDynamicTheme)
      ..writeByte(5)
      ..write(obj.fontFamily)
      ..writeByte(6)
      ..write(obj.useAmoledTheme);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ImportantDateAdapter extends TypeAdapter<ImportantDate> {
  @override
  final int typeId = 1;

  @override
  ImportantDate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ImportantDate(
      title: fields[0] as String,
      date: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ImportantDate obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportantDateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
