import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/paper.dart';
import '../../../cubits/chat/chat_cubit.dart';
import '../../../cubits/chat/chat_state.dart';
import '../../../cubits/paper_selection/paper_selection_cubit.dart';
import '../../../../app/routes.dart';

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
      duration: const Duration(milliseconds: 200),
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
    // Use sessionPapers from ChatCubit — correct for both new and historical sessions.
    // Fall back to PaperSelectionCubit only when the chat session hasn't loaded yet.
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, chatState) {
        final papers = chatState is ChatSessionLoaded
            ? chatState.sessionPapers
            : context.read<PaperSelectionCubit>().state.selectedPapers;

        if (papers.isEmpty) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final selState = context.watch<PaperSelectionCubit>().state;
        final hasIndexing = chatState is ChatSessionLoaded
            ? false // historical sessions are already indexed
            : selState.hasProcessingPapers;

        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────────────────────
              InkWell(
                onTap: _toggle,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.article_outlined,
                          size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${papers.length} paper${papers.length > 1 ? 's' : ''} in context',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (hasIndexing)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: theme.colorScheme.tertiary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text('Indexing…',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.tertiary)),
                            ],
                          ),
                        ),
                      AnimatedRotation(
                        turns: _expanded ? 0 : -0.5,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.expand_less,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Paper list ──────────────────────────────────────────────────
              SizeTransition(
                sizeFactor: _sizeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: papers.map((p) {
                    // Show the remove button only when the paper is in the
                    // *current* selection — i.e. we're in a live session.
                    final canRemove = selState.isSelected(p.arxivId);
                    final status = canRemove
                        ? selState.statusFor(p.arxivId)
                        : 'completed';
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
    final theme = Theme.of(context);

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
            // Status dot
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _statusColor(context, status),
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
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (paper.authors.isNotEmpty)
                    Text(
                      paper.authors.take(2).join(', ') +
                          (paper.authors.length > 2 ? ' et al.' : ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            // Status badge (only for non-ready papers)
            _StatusBadge(status: status),
            // Remove button only for live-session papers
            if (canRemove)
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                tooltip: 'Remove from chat',
                visualDensity: VisualDensity.compact,
                onPressed: () => context
                    .read<PaperSelectionCubit>()
                    .removePaper(paper.arxivId),
              )
            else
              // Spacer to keep alignment consistent
              const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context, String status) {
    final cs = Theme.of(context).colorScheme;
    return switch (status) {
      'completed' => Colors.green,
      'processing' => cs.tertiary,
      'failed' => cs.error,
      _ => cs.outlineVariant,
    };
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == 'completed' || status == 'idle') return const SizedBox.shrink();

    final theme = Theme.of(context);
    final (label, color) = switch (status) {
      'processing' => ('Indexing', theme.colorScheme.tertiary),
      'failed' => ('Failed', theme.colorScheme.error),
      _ => ('', theme.colorScheme.outlineVariant),
    };

    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
