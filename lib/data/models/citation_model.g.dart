// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'citation_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CitationModelAdapter extends TypeAdapter<CitationModel> {
  @override
  final int typeId = 3;

  @override
  CitationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CitationModel(
      paperTitle: fields[0] as String,
      pageNumber: fields[1] as int,
      chunkText: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CitationModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.paperTitle)
      ..writeByte(1)
      ..write(obj.pageNumber)
      ..writeByte(2)
      ..write(obj.chunkText);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CitationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
