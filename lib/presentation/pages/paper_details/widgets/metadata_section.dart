import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../domain/entities/paper.dart';
import '../../../../core/utils/date_formatter.dart';

class MetadataSection extends StatelessWidget {
  final Paper paper;

  const MetadataSection({super.key, required this.paper});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(paper.title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _row(context, Icons.person_outline, paper.authors.join(', ')),
            const SizedBox(height: 6),
            _row(context, Icons.calendar_today_outlined,
                DateFormatter.formatPublishedDate(paper.publishedDate)),
            const SizedBox(height: 6),
            _row(context, Icons.tag_outlined, paper.categories.join(' · ')),
            const SizedBox(height: 6),
            _row(context, Icons.fingerprint_outlined, paper.arxivId),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('View PDF'),
                  onPressed: () => _launch(paper.pdfUrl),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('arXiv Page'),
                  onPressed: () => _launch(
                      'https://arxiv.org/abs/${paper.arxivId}'),
                ),
              ],
            ),
            const Divider(height: 24),
            Text('Abstract', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(paper.abstract, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
