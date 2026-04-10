import 'package:hive/hive.dart';
import '../../domain/entities/paper.dart';

part 'paper_model.g.dart';

@HiveType(typeId: 0)
class PaperModel extends HiveObject {
  @HiveField(0)
  final String arxivId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final List<String> authors;

  @HiveField(3)
  final String abstract;

  @HiveField(4)
  final String pdfUrl;

  @HiveField(5)
  final DateTime publishedDate;

  @HiveField(6)
  final List<String> categories;

  PaperModel({
    required this.arxivId,
    required this.title,
    required this.authors,
    required this.abstract,
    required this.pdfUrl,
    required this.publishedDate,
    required this.categories,
  });

  Paper toEntity() => Paper(
        arxivId: arxivId,
        title: title,
        authors: authors,
        abstract: abstract,
        pdfUrl: pdfUrl,
        publishedDate: publishedDate,
        categories: categories,
      );

  factory PaperModel.fromEntity(Paper p) => PaperModel(
        arxivId: p.arxivId,
        title: p.title,
        authors: p.authors,
        abstract: p.abstract,
        pdfUrl: p.pdfUrl,
        publishedDate: p.publishedDate,
        categories: p.categories,
      );
}
