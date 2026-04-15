import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/paper.dart';
import '../../../cubits/chat/chat_cubit.dart';
import '../../../cubits/chat/chat_state.dart';
import '../../../cubits/paper_selection/paper_selection_cubit.dart';
import '../../../../app/routes.dart';
import '../../../../core/theme/colors.dart';

class ChatPapersPanel extends StatefulWidget {
  const ChatPapersPanel({super.key});

  @override
  State<ChatPapersPanel> createState() => _ChatPapersPanelState();
}

class _ChatPapersPanelState extends State<ChatPapersPanel>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;
  late final AnimationController _animController;
  late final Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _sizeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _animController.forward() : _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, chatState) {
        final papers = chatState is ChatSessionLoaded
            ? chatState.sessionPapers
            : context.read<PaperSelectionCubit>().state.selectedPapers;

        if (papers.isEmpty) return const SizedBox.shrink();

        final selState = context.watch<PaperSelectionCubit>().state;
        final hasIndexing = chatState is ChatSessionLoaded
            ? false
            : selState.hasProcessingPapers;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: const Border(
              bottom: BorderSide(color: AppColors.surfaceBorder),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              InkWell(
                onTap: _toggle,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.gradientBlue,
                              AppColors.gradientPurple,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.article_rounded,
                            color: Colors.white, size: 13),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${papers.length} paper${papers.length > 1 ? 's' : ''} in context',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (hasIndexing)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    AppColors.gradientFuchsia,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Indexing…',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.gradientFuchsia,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      AnimatedRotation(
                        turns: _expanded ? 0 : -0.5,
                        duration: const Duration(milliseconds: 250),
                        child: const Icon(Icons.expand_less_rounded,
                            size: 20, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              ),
              // Paper list
              SizeTransition(
                sizeFactor: _sizeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: papers.map((p) {
                    final canRemove = selState.isSelected(p.arxivId);
                    final status =
                        canRemove ? selState.statusFor(p.arxivId) : 'completed';
                    return _PaperRow(
                      paper: p,
                      status: status,
                      canRemove: canRemove,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaperRow extends StatelessWidget {
  final Paper paper;
  final String status;
  final bool canRemove;

  const _PaperRow({
    required this.paper,
    required this.status,
    required this.canRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.paperDetails,
        arguments: paper,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _statusColor(status),
                boxShadow: status == 'completed'
                    ? [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.4),
                          blurRadius: 4,
                        )
                      ]
                    : null,
              ),
            ),
            // Paper info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    paper.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (paper.authors.isNotEmpty)
                    Text(
                      paper.authors.take(2).join(', ') +
                          (paper.authors.length > 2 ? ' et al.' : ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            _StatusBadge(status: status),
            if (canRemove)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                tooltip: 'Remove from chat',
                visualDensity: VisualDensity.compact,
                color: AppColors.textTertiary,
                onPressed: () => context
                    .read<PaperSelectionCubit>()
                    .removePaper(paper.arxivId),
              )
            else
              const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'completed' => AppColors.success,
      'processing' => AppColors.gradientFuchsia,
      'failed' => AppColors.error,
      _ => AppColors.textTertiary,
    };
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == 'completed' || status == 'idle') {
      return const SizedBox.shrink();
    }

    final (label, color) = switch (status) {
      'processing' => ('Indexing', AppColors.gradientFuchsia),
      'failed' => ('Failed', AppColors.error),
      _ => ('', AppColors.textTertiary),
    };

    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
