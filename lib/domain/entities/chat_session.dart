import 'package:equatable/equatable.dart';
import 'message.dart';

class ChatSession extends Equatable {
  final String sessionId;
  final List<String> paperIds;
  final Map<String, String> paperTitles;
  final List<Message> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatSession({
    required this.sessionId,
    required this.paperIds,
    this.paperTitles = const {},
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  ChatSession copyWith({
    List<String>? paperIds,
    Map<String, String>? paperTitles,
    List<Message>? messages,
    DateTime? updatedAt,
  }) {
    return ChatSession(
      sessionId: sessionId,
      paperIds: paperIds ?? this.paperIds,
      paperTitles: paperTitles ?? this.paperTitles,
      messages: messages ?? this.messages,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayTitle {
    if (paperTitles.isNotEmpty) return paperTitles.values.join(', ');
    return paperIds.join(', ');
  }

  String get lastMessagePreview {
    if (messages.isEmpty) return 'No messages yet';
    final last = messages.last;
    final content = last.content;
    return content.length > 80 ? '${content.substring(0, 80)}…' : content;
  }

  @override
  List<Object?> get props => [sessionId, paperIds, paperTitles, messages, createdAt, updatedAt];
}
