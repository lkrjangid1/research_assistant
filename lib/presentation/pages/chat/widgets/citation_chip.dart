import 'package:flutter/material.dart';
import '../../../../domain/entities/message.dart';
import '../../../../core/theme/colors.dart';

class CitationChip extends StatelessWidget {
  final Citation citation;

  const CitationChip({super.key, required this.citation});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: citation.chunkText,
      decoration: BoxDecoration(
        color: cs.inverseSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: TextStyle(color: cs.onInverseSurface, fontSize: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.gradientBlue,
                    AppColors.gradientSlateBlue,
                  ],
                ),
              ),
              child: const Icon(Icons.format_quote_rounded,
                  color: Colors.white, size: 8),
            ),
            const SizedBox(width: 5),
            Text(
              '[${_shortTitle(citation.paperTitle)}, p.${citation.pageNumber}]',
              style: TextStyle(
                fontSize: 11,
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortTitle(String title) {
    final words = title.split(' ');
    return words.length <= 3 ? title : '${words.take(3).join(' ')}…';
  }
}
