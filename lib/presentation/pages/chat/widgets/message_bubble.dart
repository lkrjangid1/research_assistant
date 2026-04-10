import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../domain/entities/message.dart';
import '../../../../core/utils/date_formatter.dart';
import 'citation_chip.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 48 : 16,
        right: isUser ? 16 : 48,
        top: 4,
        bottom: 4,
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
            ),
            child: isUser
                ? Text(
                    message.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : MarkdownBody(
                    data: message.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                      p: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      code: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      blockquote: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: theme.colorScheme.outline,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          if (!isUser && message.citations != null && message.citations!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: message.citations!
                    .map((c) => CitationChip(citation: c))
                    .toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
            child: Text(
              DateFormatter.timeAgo(message.timestamp),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
