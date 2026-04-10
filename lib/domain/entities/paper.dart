import 'package:equatable/equatable.dart';

class Paper extends Equatable {
  final String arxivId;
  final String title;
  final List<String> authors;
  final String abstract;
  final String pdfUrl;
  final DateTime publishedDate;
  final List<String> categories;

  const Paper({
    required this.arxivId,
    required this.title,
    required this.authors,
    required this.abstract,
    required this.pdfUrl,
    required this.publishedDate,
    required this.categories,
  });

  String get primaryCategory => categories.isNotEmpty ? categories.first : '';

  @override
  List<Object?> get props => [arxivId, title, authors, abstract, pdfUrl, publishedDate, categories];
}
