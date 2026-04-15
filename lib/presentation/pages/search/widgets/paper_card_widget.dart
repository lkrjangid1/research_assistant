import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/paper.dart';
import '../../../cubits/paper_selection/paper_selection_cubit.dart';
import '../../../cubits/paper_selection/paper_selection_state.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/theme/colors.dart';
import '../../../../app/routes.dart';

class PaperCardWidget extends StatelessWidget {
  final Paper paper;

  const PaperCardWidget({super.key, required this.paper});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaperSelectionCubit, PaperSelectionState>(
      builder: (context, selectionState) {
        final isSelected = selectionState.isSelected(paper.arxivId);
        final canAdd = selectionState.canAddMore;
        final status = selectionState.statusFor(paper.arxivId);
        final isProcessing = status == 'processing';
        final hasFailed = status == 'failed';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: _PaperCardContent(
            paper: paper,
            isSelected: isSelected,
            canAdd: canAdd,
            isProcessing: isProcessing,
            hasFailed: hasFailed,
          ),
        );
      },
    );
  }
}

class _PaperCardContent extends StatefulWidget {
  final Paper paper;
  final bool isSelected;
  final bool canAdd;
  final bool isProcessing;
  final bool hasFailed;

  const _PaperCardContent({
    required this.paper,
    required this.isSelected,
    required this.canAdd,
    required this.isProcessing,
    required this.hasFailed,
  });

  @override
  State<_PaperCardContent> createState() => _PaperCardContentState();
}

class _PaperCardContentState extends State<_PaperCardContent> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isSelected
                ? AppColors.gradientBlue.withValues(alpha: 0.4)
                : AppColors.surfaceBorder,
            width: widget.isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                  alpha: _hovered ? 0.08 : 0.04),
              blurRadius: _hovered ? 24 : 8,
              offset: Offset(0, _hovered ? 8 : 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.paperDetails,
            arguments: widget.paper,
          ),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.paper.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.isSelected) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.gradientBlue,
                              AppColors.gradientSlateBlue
                            ],
                          ),
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                // Authors
                Text(
                  widget.paper.authors.take(3).join(', ') +
                      (widget.paper.authors.length > 3 ? ' et al.' : ''),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                // Meta row: date + categories
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      DateFormatter.formatPublishedDate(
                          widget.paper.publishedDate),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textTertiary),
                    ),
                    const SizedBox(width: 12),
                    ...widget.paper.categories.take(2).map(
                          (cat) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _CategoryTag(label: cat),
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 10),
                // Abstract preview
                Text(
                  widget.paper.abstract,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                // Action button
                Align(
                  alignment: Alignment.centerRight,
                  child: widget.isSelected
                      ? _RemoveButton(
                          label: widget.isProcessing
                              ? 'Indexing…'
                              : widget.hasFailed
                                  ? 'Remove (failed)'
                                  : 'Remove',
                          onTap: () => context
                              .read<PaperSelectionCubit>()
                              .removePaper(widget.paper.arxivId),
                        )
                      : _AddButton(
                          enabled: widget.canAdd,
                          onTap: widget.canAdd
                              ? () => context
                                  .read<PaperSelectionCubit>()
                                  .addPaper(widget.paper)
                              : null,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final String label;
  const _CategoryTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.gradientBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.gradientBlue,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onTap;
  const _AddButton({required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [
                    AppColors.gradientBlue,
                    AppColors.gradientSlateBlue,
                  ],
                )
              : null,
          color: enabled ? null : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              size: 15,
              color: enabled ? Colors.white : AppColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              'Add to Chat',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.white : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _RemoveButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.remove_circle_outline_rounded,
                size: 15, color: AppColors.error),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
