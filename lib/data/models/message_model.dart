import 'package:hive/hive.dart';
import '../../domain/entities/message.dart';
import 'citation_model.dart';

part 'message_model.g.dart';

@HiveType(typeId: 2)
class MessageModel extends HiveObject {
  @HiveField(0)
  final String messageId;

  @HiveField(1)
  final String role;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final List<CitationModel>? citations;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final String? slashCommand;

  MessageModel({
    required this.messageId,
    required this.role,
    required this.content,
    this.citations,
    required this.timestamp,
    this.slashCommand,
  });

  Message toEntity() => Message(
        messageId: messageId,
        role: role,
        content: content,
        citations: citations?.map((c) => c.toEntity()).toList(),
        timestamp: timestamp,
        slashCommand: slashCommand,
      );

  factory MessageModel.fromEntity(Message m) => MessageModel(
        messageId: m.messageId,
        role: m.role,
        content: m.content,
        citations: m.citations?.map(CitationModel.fromEntity).toList(),
        timestamp: m.timestamp,
        slashCommand: m.slashCommand,
      );
}
