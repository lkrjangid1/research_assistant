import 'package:flutter/material.dart';
import '../../../../domain/entities/message.dart';
import '../../../../core/theme/colors.dart';

class CitationChip extends StatelessWidget {
  final Citation citation;

  const CitationChip({super.key, required this.citation});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: citation.chunkText,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.citationHighlight,
          border: Border.all(color: AppColors.citationBorder),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '[${_shortTitle(citation.paperTitle)}, p.${citation.pageNumber}]',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _shortTitle(String title) {
    final words = title.split(' ');
    return words.length <= 3 ? title : '${words.take(3).join(' ')}…';
  }
}
