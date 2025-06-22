// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_inspection.dart';

class LocalInspectionAdapter extends TypeAdapter<LocalInspection> {
  @override
  final int typeId = 0;

  @override
  LocalInspection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalInspection(
      inspectionId: fields[0] as String,
      metadata: (fields[1] as Map).cast<String, dynamic>(),
      photos: (fields[2] as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList(),
      isSynced: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LocalInspection obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.inspectionId)
      ..writeByte(1)
      ..write(obj.metadata)
      ..writeByte(2)
      ..write(obj.photos)
      ..writeByte(3)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalInspectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
