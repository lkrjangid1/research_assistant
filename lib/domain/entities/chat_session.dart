import 'package:equatable/equatable.dart';
import 'message.dart';

class ChatSession extends Equatable {
  final String sessionId;
  final List<String> paperIds;
  final List<Message> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatSession({
    required this.sessionId,
    required this.paperIds,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  ChatSession copyWith({
    List<Message>? messages,
    DateTime? updatedAt,
  }) {
    return ChatSession(
      sessionId: sessionId,
      paperIds: paperIds,
      messages: messages ?? this.messages,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [sessionId, paperIds, messages, createdAt, updatedAt];
}
