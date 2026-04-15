import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/paper_selection/paper_selection_cubit.dart';
import '../cubits/paper_selection/paper_selection_state.dart';
import '../../app/routes.dart';
import '../../core/theme/colors.dart';

class PaperSelectionBar extends StatelessWidget {
  const PaperSelectionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaperSelectionCubit, PaperSelectionState>(
      builder: (context, state) {
        if (state.selectedPapers.isEmpty) return const SizedBox.shrink();
        final cs = Theme.of(context).colorScheme;

        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(top: BorderSide(color: cs.outlineVariant)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: state.selectedPapers.map((paper) {
                            final status = state.statusFor(paper.arxivId);
                            return _PaperChip(
                              title: paper.title,
                              status: status,
                              cs: cs,
                              onRemove: () => context
                                  .read<PaperSelectionCubit>()
                                  .removePaper(paper.arxivId),
                            );
                          }).toList(),
                        ),
                        if (state.hasProcessingPapers) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.gradientFuchsia,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Preparing papers for chat…',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (state.error != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            state.error!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: state.allPapersReady
                        ? () =>
                            Navigator.pushNamed(context, AppRoutes.chat)
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 11),
                      decoration: BoxDecoration(
                        gradient: state.allPapersReady
                            ? const LinearGradient(
                                colors: [
                                  AppColors.gradientBlue,
                                  AppColors.gradientSlateBlue,
                                ],
                              )
                            : null,
                        color: state.allPapersReady
                            ? null
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: state.allPapersReady
                            ? [
                                BoxShadow(
                                  color: AppColors.gradientBlue
                                      .withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 16,
                            color: state.allPapersReady
                                ? Colors.white
                                : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Chat (${state.selectedPapers.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: state.allPapersReady
                                  ? Colors.white
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
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

class _PaperChip extends StatelessWidget {
  final String title;
  final String status;
  final ColorScheme cs;
  final VoidCallback onRemove;

  const _PaperChip({
    required this.title,
    required this.status,
    required this.cs,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isProcessing = status == 'processing';
    final isFailed = status == 'failed';
    final shortTitle =
        title.length > 24 ? '${title.substring(0, 24)}…' : title;
    final suffix = isProcessing
        ? ' · indexing'
        : isFailed
            ? ' · failed'
            : '';

    final chipColor =
        isFailed ? AppColors.error : AppColors.gradientBlue;

    return Container(
      padding:
          const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: chipColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$shortTitle$suffix',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: chipColor,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: chipColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded,
                  size: 10, color: chipColor),
            ),
          ),
        ],
      ),
    );
  }
}
