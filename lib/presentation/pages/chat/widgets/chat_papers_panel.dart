import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
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
  bool _isUploadingPdf = false;
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

  /// Navigate to search so the user can pick an additional paper.
  /// Any paper added to PaperSelectionCubit during that visit is synced
  /// into the current chat session on return.
  Future<void> _attachPaper() async {
    final selCubit = context.read<PaperSelectionCubit>();
    final chatCubit = context.read<ChatCubit>();
    final papersBefore =
        selCubit.state.selectedPapers.map((p) => p.arxivId).toSet();

    await Navigator.pushNamed(context, AppRoutes.search);

    if (!context.mounted) return;

    final newPapers = selCubit.state.selectedPapers
        .where((p) => !papersBefore.contains(p.arxivId))
        .toList();

    for (final paper in newPapers) {
      chatCubit.addPaperToSession(paper);
    }
  }

  Future<void> _showAttachOptions() async {
    final choice = await showModalBottomSheet<_AttachOption>(
      context: context,
      builder: (sheetContext) {
        final cs = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AttachOptionTile(
                icon: Icons.search_rounded,
                title: 'Add arXiv paper',
                subtitle: 'Search and attach another indexed paper',
                color: AppColors.gradientBlue,
                cs: cs,
                onTap: () => Navigator.pop(sheetContext, _AttachOption.search),
              ),
              _AttachOptionTile(
                icon: Icons.picture_as_pdf_rounded,
                title: 'Upload PDF',
                subtitle:
                    'Pick a paper PDF from this device and index it for chat',
                color: AppColors.gradientFuchsia,
                cs: cs,
                onTap: () => Navigator.pop(sheetContext, _AttachOption.upload),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || choice == null) return;
    if (choice == _AttachOption.search) {
      await _attachPaper();
      return;
    }
    await _uploadPdf();
  }

  Future<void> _uploadPdf() async {
    if (_isUploadingPdf) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read the selected PDF file.')),
      );
      return;
    }

    setState(() => _isUploadingPdf = true);
    final selectionCubit = context.read<PaperSelectionCubit>();
    final chatCubit = context.read<ChatCubit>();
    final paper = await selectionCubit.uploadPdf(
      filename: file.name,
      pdfBytes: bytes,
    );

    if (!mounted) return;
    setState(() => _isUploadingPdf = false);

    if (paper == null) {
      final error = selectionCubit.state.error ?? 'Failed to upload PDF';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    chatCubit.addPaperToSession(paper);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${paper.title} added to chat context')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, chatState) {
        final papers = chatState is ChatSessionLoaded
            ? chatState.sessionPapers
            : context.read<PaperSelectionCubit>().state.selectedPapers;

        if (papers.isEmpty) return const SizedBox.shrink();

        final selState = context.watch<PaperSelectionCubit>().state;
        // Show indexing indicator when any paper is still being processed
        final hasIndexing = selState.hasProcessingPapers;
        final canAddMore = papers.length < AppConstants.maxPapersPerSession;

        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(bottom: BorderSide(color: cs.outlineVariant)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (hasIndexing)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
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
                      // Attach paper button
                      if (canAddMore)
                        Tooltip(
                          message: 'Add paper',
                          child: InkWell(
                            onTap: _isUploadingPdf ? null : _showAttachOptions,
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _isUploadingPdf
                                      ? SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.6,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              cs.primary,
                                            ),
                                          ),
                                        )
                                      : Icon(Icons.attach_file_rounded,
                                          size: 14, color: cs.primary),
                                  const SizedBox(width: 3),
                                  Text(
                                    _isUploadingPdf ? 'Uploading' : 'Attach',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0 : -0.5,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(Icons.expand_less_rounded,
                            size: 20, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              SizeTransition(
                sizeFactor: _sizeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: papers.map((p) {
                    // Status: use live value from PaperSelectionCubit if available,
                    // otherwise the paper was loaded from history and is already indexed.
                    final status = selState.isSelected(p.arxivId)
                        ? selState.statusFor(p.arxivId)
                        : 'completed';
                    // Can remove as long as the session has more than one paper
                    final canRemove = papers.length > 1;
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

enum _AttachOption { search, upload }

class _AttachOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _AttachOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: cs.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
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
    final cs = Theme.of(context).colorScheme;

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
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _statusColor(status),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    paper.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  if (paper.authors.isNotEmpty)
                    Text(
                      paper.authors.take(2).join(', ') +
                          (paper.authors.length > 2 ? ' et al.' : ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            _StatusBadge(status: status),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 16,
                color: canRemove
                    ? cs.onSurfaceVariant
                    : cs.onSurfaceVariant.withValues(alpha: 0.3),
              ),
              tooltip:
                  canRemove ? 'Remove from chat' : 'Cannot remove last paper',
              visualDensity: VisualDensity.compact,
              onPressed: canRemove
                  ? () {
                      // Remove from session state (works for both new and history sessions)
                      context
                          .read<ChatCubit>()
                          .removePaperFromSession(paper.arxivId);
                      // Also remove from PaperSelectionCubit if it's currently selected
                      final selCubit = context.read<PaperSelectionCubit>();
                      if (selCubit.state.isSelected(paper.arxivId)) {
                        selCubit.removePaper(paper.arxivId);
                      }
                    }
                  : null,
            ),
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
