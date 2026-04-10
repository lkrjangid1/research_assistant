import 'package:xml/xml.dart';
import '../../domain/entities/paper.dart';

/// Parses arXiv Atom/XML search responses into [Paper] entities.
class ArxivXmlParser {
  static const _atom = 'http://www.w3.org/2005/Atom';

  static List<Paper> parseSearchResponse(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final entries = document.findAllElements('entry', namespace: _atom);
    return entries.map(_parseEntry).whereType<Paper>().toList();
  }

  static Paper? _parseEntry(XmlElement entry) {
    try {
      final idRaw = _text(entry, 'id') ?? '';
      final arxivId = _extractArxivId(idRaw);
      final title = _text(entry, 'title')?.trim().replaceAll('\n', ' ') ?? '';
      final abstract = _text(entry, 'summary')?.trim().replaceAll('\n', ' ') ?? '';

      // Published date
      final publishedStr = _text(entry, 'published') ?? '';
      final publishedDate = DateTime.tryParse(publishedStr) ?? DateTime.now();

      // Authors
      final authors = entry
          .findAllElements('author', namespace: _atom)
          .map((a) => _text(a, 'name')?.trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      // PDF URL from <link title="pdf">
      String pdfUrl = '';
      for (final link in entry.findAllElements('link', namespace: _atom)) {
        if (link.getAttribute('title') == 'pdf') {
          pdfUrl = link.getAttribute('href') ?? '';
          break;
        }
      }
      if (pdfUrl.isEmpty && arxivId.isNotEmpty) {
        pdfUrl = 'https://arxiv.org/pdf/$arxivId.pdf';
      }

      // Categories
      final categories = entry
          .findAllElements('category', namespace: _atom)
          .map((c) => c.getAttribute('term') ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      return Paper(
        arxivId: arxivId,
        title: title,
        authors: authors,
        abstract: abstract,
        pdfUrl: pdfUrl,
        publishedDate: publishedDate,
        categories: categories,
      );
    } catch (_) {
      return null;
    }
  }

  static String _extractArxivId(String raw) {
    // e.g. http://arxiv.org/abs/2401.12345v1 → 2401.12345
    final match = RegExp(r'arxiv\.org/abs/([^\s/v]+)').firstMatch(raw);
    return match?.group(1) ?? raw;
  }

  static String? _text(XmlElement el, String name) {
    try {
      return el.findElements(name, namespace: _atom).first.innerText;
    } catch (_) {
      try {
        return el.findElements(name).first.innerText;
      } catch (_) {
        return null;
      }
    }
  }
}
