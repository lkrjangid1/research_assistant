import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/paper.dart';
import '../../../cubits/paper_selection/paper_selection_cubit.dart';
import '../../../cubits/paper_selection/paper_selection_state.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../app/routes.dart';

class PaperCardWidget extends StatelessWidget {
  final Paper paper;

  const PaperCardWidget({super.key, required this.paper});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<PaperSelectionCubit, PaperSelectionState>(
      builder: (context, selectionState) {
        final isSelected = selectionState.isSelected(paper.arxivId);
        final canAdd = selectionState.canAddMore;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.paperDetails,
              arguments: paper,
            ),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          paper.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isSelected)
                        Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    paper.authors.take(3).join(', ') +
                        (paper.authors.length > 3 ? ' et al.' : ''),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 12, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        DateFormatter.formatPublishedDate(paper.publishedDate),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ...paper.categories.take(2).map((cat) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Chip(
                              label: Text(cat, style: const TextStyle(fontSize: 10)),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    paper.abstract,
                    style: theme.textTheme.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: isSelected
                        ? OutlinedButton.icon(
                            onPressed: () => context
                                .read<PaperSelectionCubit>()
                                .removePaper(paper.arxivId),
                            icon: const Icon(Icons.remove_circle_outline, size: 16),
                            label: const Text('Remove'),
                          )
                        : FilledButton.icon(
                            onPressed: canAdd
                                ? () => context
                                    .read<PaperSelectionCubit>()
                                    .addPaper(paper)
                                : null,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add to Chat'),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
