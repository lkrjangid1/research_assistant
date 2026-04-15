import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/theme/colors.dart';
import '../../../domain/entities/chat_session.dart';
import '../../cubits/chat_history/chat_history_cubit.dart';
import '../../cubits/chat_history/chat_history_state.dart';

class ChatHistoryPage extends StatelessWidget {
  const ChatHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatHistoryCubit>(
      create: (_) => sl<ChatHistoryCubit>()..loadSessions(),
      child: const _ChatHistoryView(),
    );
  }
}

class _ChatHistoryView extends StatelessWidget {
  const _ChatHistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.gradientBlue,
                    AppColors.gradientPurple,
                  ],
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.history_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Chat History'),
          ],
        ),
      ),
      body: BlocBuilder<ChatHistoryCubit, ChatHistoryState>(
        builder: (context, state) {
          if (state is ChatHistoryInitial) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.gradientBlue,
                ),
              ),
            );
          }

          if (state is ChatHistoryEmpty) {
            return _buildEmptyState();
          }

          if (state is ChatHistoryLoaded) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.sessions.length,
              itemBuilder: (context, i) =>
                  _SessionCard(session: state.sessions[i]),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gradientBlue.withValues(alpha: 0.12),
                  AppColors.gradientPurple.withValues(alpha: 0.12),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded,
                size: 36, color: AppColors.gradientBlue),
          ),
          const SizedBox(height: 20),
          const Text(
            'No past sessions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add papers and start a chat\nto see history here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatefulWidget {
  final ChatSession session;

  const _SessionCard({required this.session});

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(widget.session.sessionId),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 20),
          ),
        ),
        confirmDismiss: (_) => _confirmDelete(context),
        onDismissed: (_) => context
            .read<ChatHistoryCubit>()
            .deleteSession(widget.session.sessionId),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBorder),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withValues(alpha: _hovered ? 0.08 : 0.03),
                  blurRadius: _hovered ? 20 : 8,
                  offset: Offset(0, _hovered ? 6 : 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _resumeSession(context),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.gradientBlue,
                              AppColors.gradientPurple,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${widget.session.messages.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.session.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.session.lastMessagePreview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    size: 11,
                                    color: AppColors.textTertiary),
                                const SizedBox(width: 3),
                                Text(
                                  DateFormatter.timeAgo(
                                      widget.session.updatedAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.article_outlined,
                                    size: 11,
                                    color: AppColors.textTertiary),
                                const SizedBox(width: 3),
                                Text(
                                  '${widget.session.paperIds.length} paper${widget.session.paperIds.length > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textTertiary, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Session?'),
        content: const Text(
            'This chat history will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context, true),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resumeSession(BuildContext context) {
    Navigator.pop(context, widget.session.sessionId);
  }
}
