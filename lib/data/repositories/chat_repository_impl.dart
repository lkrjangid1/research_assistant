import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../core/network/api_exceptions.dart';
import '../datasources/remote/backend_api_service.dart';
import '../datasources/local/chat_local_datasource.dart';
import '../models/chat_session_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final BackendApiService _backendApi;
  final ChatLocalDatasource _localDs;

  ChatRepositoryImpl(this._backendApi, this._localDs);

  @override
  Future<Either<Failure, Message>> sendChatQuery({
    required String question,
    required List<String> paperIds,
    required Map<String, String> paperTitles,
    String? sessionId,
    String? expertiseLevel,
  }) async {
    try {
      final data = await _backendApi.chatQuery(
        question: question,
        paperIds: paperIds,
        paperTitles: paperTitles,
        sessionId: sessionId,
        expertiseLevel: expertiseLevel,
      );
      return Right(_messageFromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Chat query failed: $e'));
    }
  }

  @override
  Future<Either<Failure, Message>> executeSlashCommand({
    required String command,
    required String? argument,
    required List<String> paperIds,
    required Map<String, String> paperTitles,
    String? sessionId,
  }) async {
    try {
      final data = await _backendApi.executeCommand(
        command: command,
        paperIds: paperIds,
        paperTitles: paperTitles,
        argument: argument,
        sessionId: sessionId,
      );
      return Right(_messageFromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Command failed: $e'));
    }
  }

  @override
  Future<Either<Failure, ChatSession?>> getSession(String sessionId) async {
    try {
      final model = _localDs.getSession(sessionId);
      return Right(model?.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to load session: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ChatSession>>> getAllSessions() async {
    try {
      final sessions = _localDs.getAllSessions().map((m) => m.toEntity()).toList();
      return Right(sessions);
    } catch (e) {
      return Left(CacheFailure('Failed to load sessions: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveSession(ChatSession session) async {
    try {
      await _localDs.saveSession(ChatSessionModel.fromEntity(session));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to save session: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSession(String sessionId) async {
    try {
      await _localDs.deleteSession(sessionId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to delete session: $e'));
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Message _messageFromJson(Map<String, dynamic> json) {
    final citationsJson = (json['citations'] as List<dynamic>?) ?? [];
    final citations = citationsJson
        .cast<Map<String, dynamic>>()
        .map((c) => Citation(
              paperTitle: c['paper_title'] as String,
              pageNumber: c['page_number'] as int,
              chunkText: c['excerpt'] as String? ?? '',
            ))
        .toList();
    return Message(
      messageId: const Uuid().v4(),
      role: 'assistant',
      content: json['text'] as String,
      citations: citations,
      timestamp: DateTime.now(),
    );
  }
}
