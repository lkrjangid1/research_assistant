import 'package:hive/hive.dart';
import '../../domain/entities/message.dart';

part 'citation_model.g.dart';

@HiveType(typeId: 3)
class CitationModel extends HiveObject {
  @HiveField(0)
  final String paperTitle;

  @HiveField(1)
  final int pageNumber;

  @HiveField(2)
  final String chunkText;

  CitationModel({
    required this.paperTitle,
    required this.pageNumber,
    required this.chunkText,
  });

  Citation toEntity() => Citation(
        paperTitle: paperTitle,
        pageNumber: pageNumber,
        chunkText: chunkText,
      );

  factory CitationModel.fromEntity(Citation c) => CitationModel(
        paperTitle: c.paperTitle,
        pageNumber: c.pageNumber,
        chunkText: c.chunkText,
      );
}
