import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/chat_session.dart';
import '../../cubits/chat_history/chat_history_cubit.dart';
import '../../cubits/chat_history/chat_history_state.dart';
import '../../../app/routes.dart';

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
      appBar: AppBar(title: const Text('Chat History')),
      body: BlocBuilder<ChatHistoryCubit, ChatHistoryState>(
        builder: (context, state) {
          if (state is ChatHistoryInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ChatHistoryEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No past sessions',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Add papers and start a chat to see history here.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          if (state is ChatHistoryLoaded) {
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.sessions.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (context, i) =>
                  _SessionTile(session: state.sessions[i]),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final ChatSession session;

  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(session.sessionId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: theme.colorScheme.errorContainer,
        child: Icon(Icons.delete_outline,
            color: theme.colorScheme.onErrorContainer),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) =>
          context.read<ChatHistoryCubit>().deleteSession(session.sessionId),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            '${session.messages.length}',
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        title: Text(
          session.displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              session.lastMessagePreview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 12, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  DateFormatter.timeAgo(session.updatedAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                Icon(Icons.article_outlined,
                    size: 12, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${session.paperIds.length} paper${session.paperIds.length > 1 ? 's' : ''}',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _resumeSession(context),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Session?'),
        content: const Text('This chat history will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _resumeSession(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.chat,
      arguments: ChatRouteArgs(sessionId: session.sessionId),
    );
  }
}
