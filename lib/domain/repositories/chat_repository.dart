import 'package:dartz/dartz.dart';
import '../entities/message.dart';
import '../entities/chat_session.dart';
import '../../core/network/api_exceptions.dart';

abstract class ChatRepository {
  Future<Either<Failure, Message>> sendChatQuery({
    required String question,
    required List<String> paperIds,
    required Map<String, String> paperTitles,
    String? sessionId,
    String? expertiseLevel,
  });

  Future<Either<Failure, Message>> executeSlashCommand({
    required String command,
    required String? argument,
    required List<String> paperIds,
    required Map<String, String> paperTitles,
    String? sessionId,
  });

  // Local Hive operations
  Future<Either<Failure, ChatSession?>> getSession(String sessionId);
  Future<Either<Failure, List<ChatSession>>> getAllSessions();
  Future<Either<Failure, void>> saveSession(ChatSession session);
  Future<Either<Failure, void>> deleteSession(String sessionId);
}
