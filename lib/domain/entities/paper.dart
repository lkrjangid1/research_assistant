import 'package:equatable/equatable.dart';

class Paper extends Equatable {
  final String arxivId;
  final String title;
  final List<String> authors;
  final String abstract;
  final String pdfUrl;
  final DateTime publishedDate;
  final List<String> categories;
  final int? pdfSizeBytes;

  const Paper({
    required this.arxivId,
    required this.title,
    required this.authors,
    required this.abstract,
    required this.pdfUrl,
    required this.publishedDate,
    required this.categories,
    this.pdfSizeBytes,
  });

  String get primaryCategory => categories.isNotEmpty ? categories.first : '';

  Paper copyWith({
    String? arxivId,
    String? title,
    List<String>? authors,
    String? abstract,
    String? pdfUrl,
    DateTime? publishedDate,
    List<String>? categories,
    int? pdfSizeBytes,
  }) {
    return Paper(
      arxivId: arxivId ?? this.arxivId,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      abstract: abstract ?? this.abstract,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      publishedDate: publishedDate ?? this.publishedDate,
      categories: categories ?? this.categories,
      pdfSizeBytes: pdfSizeBytes ?? this.pdfSizeBytes,
    );
  }

  @override
  List<Object?> get props => [
        arxivId,
        title,
        authors,
        abstract,
        pdfUrl,
        publishedDate,
        categories,
        pdfSizeBytes,
      ];
}
