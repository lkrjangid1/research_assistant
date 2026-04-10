import 'package:hive/hive.dart';
import '../../domain/entities/chat_session.dart';
import 'message_model.dart';

part 'chat_session_model.g.dart';

@HiveType(typeId: 1)
class ChatSessionModel extends HiveObject {
  @HiveField(0)
  final String sessionId;

  @HiveField(1)
  final List<String> paperIds;

  @HiveField(2)
  final List<MessageModel> messages;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime updatedAt;

  @HiveField(5)
  final Map<String, String> paperTitles;

  ChatSessionModel({
    required this.sessionId,
    required this.paperIds,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.paperTitles = const {},
  });

  ChatSession toEntity() => ChatSession(
        sessionId: sessionId,
        paperIds: paperIds,
        paperTitles: paperTitles,
        messages: messages.map((m) => m.toEntity()).toList(),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory ChatSessionModel.fromEntity(ChatSession s) => ChatSessionModel(
        sessionId: s.sessionId,
        paperIds: s.paperIds,
        paperTitles: s.paperTitles,
        messages: s.messages.map(MessageModel.fromEntity).toList(),
        createdAt: s.createdAt,
        updatedAt: s.updatedAt,
      );
}
