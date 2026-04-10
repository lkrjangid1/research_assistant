// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paper_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaperModelAdapter extends TypeAdapter<PaperModel> {
  @override
  final int typeId = 0;

  @override
  PaperModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaperModel(
      arxivId: fields[0] as String,
      title: fields[1] as String,
      authors: (fields[2] as List).cast<String>(),
      abstract: fields[3] as String,
      pdfUrl: fields[4] as String,
      publishedDate: fields[5] as DateTime,
      categories: (fields[6] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, PaperModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.arxivId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.authors)
      ..writeByte(3)
      ..write(obj.abstract)
      ..writeByte(4)
      ..write(obj.pdfUrl)
      ..writeByte(5)
      ..write(obj.publishedDate)
      ..writeByte(6)
      ..write(obj.categories);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaperModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
