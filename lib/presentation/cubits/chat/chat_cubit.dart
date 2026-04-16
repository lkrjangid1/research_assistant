import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/hive_keys.dart';
import '../../../data/models/paper_model.dart';
import '../../../domain/entities/chat_session.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/entities/paper.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../domain/usecases/send_chat_message.dart';
import '../../../domain/usecases/process_slash_command.dart';
import '../../../core/constants/app_constants.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final SendChatMessage _sendMessage;
  final ProcessSlashCommand _processCommand;
  final ChatRepository _chatRepository;

  late ChatSession _session;
  final List<Message> _messages = [];

  ChatCubit(this._sendMessage, this._processCommand, this._chatRepository)
      : super(const ChatInitial());

  void initSession(List<Paper> papers) {
    _session = ChatSession(
      sessionId: const Uuid().v4(),
      paperIds: papers.map((p) => p.arxivId).toList(),
      paperTitles: {for (final p in papers) p.arxivId: p.title},
      messages: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _messages.clear();
    emit(ChatSessionLoaded(
      session: _session,
      messages: const [],
      sessionPapers: papers,
    ));
  }

  Future<void> loadSession(String sessionId) async {
    final result = await _chatRepository.getSession(sessionId);
    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (session) {
        if (session != null) {
          _session = session;
          _messages
            ..clear()
            ..addAll(session.messages);
          // Reconstruct full Paper objects from the cached papersBox
          final box = Hive.box<PaperModel>(HiveKeys.papersBox);
          final papers = session.paperIds
              .map((id) => box.get(id)?.toEntity())
              .whereType<Paper>()
              .toList();
          emit(ChatSessionLoaded(
            session: _session,
            messages: List.from(_messages),
            sessionPapers: papers,
            isResumedSession: true,
          ));
        }
      },
    );
  }

  Future<void> sendMessage(String content, Map<String, String> paperTitles) async {
    if (content.trim().isEmpty) return;

    final currentState = state;
    if (currentState is! ChatSessionLoaded) return;

    if (content.trimLeft().startsWith('/')) {
      await _handleSlashCommand(content.trim(), paperTitles);
      return;
    }

    final userMsg = Message(
      messageId: const Uuid().v4(),
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    );
    _addMessage(userMsg);
    emit(currentState.copyWith(messages: List.from(_messages), isProcessing: true));

    final result = await _sendMessage(
      question: content,
      paperIds: _session.paperIds,
      paperTitles: paperTitles,
      sessionId: _session.sessionId,
    );

    result.fold(
      (failure) {
        emit(currentState.copyWith(messages: List.from(_messages), isProcessing: false));
        emit(ChatError(failure.message));
      },
      (response) {
        _addMessage(response);
        _persistSession();
        emit(currentState.copyWith(
          messages: List.from(_messages),
          isProcessing: false,
        ));
      },
    );
  }

  Future<void> _handleSlashCommand(String raw, Map<String, String> paperTitles) async {
    final currentState = state;
    if (currentState is! ChatSessionLoaded) return;

    final userMsg = Message(
      messageId: const Uuid().v4(),
      role: 'user',
      content: raw,
      timestamp: DateTime.now(),
      slashCommand: raw.split(' ').first,
    );
    _addMessage(userMsg);
    emit(currentState.copyWith(messages: List.from(_messages), isProcessing: true));

    final result = await _processCommand(
      rawCommand: raw,
      paperIds: _session.paperIds,
      paperTitles: paperTitles,
      sessionId: _session.sessionId,
    );

    result.fold(
      (failure) => emit(currentState.copyWith(
        messages: List.from(_messages),
        isProcessing: false,
      )),
      (response) {
        _addMessage(response);
        _persistSession();
        emit(currentState.copyWith(
          messages: List.from(_messages),
          isProcessing: false,
        ));
      },
    );
  }

  void addPaperToSession(Paper paper) {
    if (_session.paperIds.contains(paper.arxivId)) return;
    if (_session.paperIds.length >= AppConstants.maxPapersPerSession) return;

    _session = _session.copyWith(
      paperIds: [..._session.paperIds, paper.arxivId],
      paperTitles: {..._session.paperTitles, paper.arxivId: paper.title},
      updatedAt: DateTime.now(),
    );

    final current = state;
    if (current is ChatSessionLoaded) {
      emit(current.copyWith(sessionPapers: [...current.sessionPapers, paper]));
      _persistSession();
    }
  }

  void removePaperFromSession(String arxivId) {
    if (!_session.paperIds.contains(arxivId)) return;

    final newIds = _session.paperIds.where((id) => id != arxivId).toList();
    final newTitles = Map<String, String>.from(_session.paperTitles)..remove(arxivId);
    _session = _session.copyWith(
      paperIds: newIds,
      paperTitles: newTitles,
      updatedAt: DateTime.now(),
    );

    final current = state;
    if (current is ChatSessionLoaded) {
      emit(current.copyWith(
        sessionPapers: current.sessionPapers.where((p) => p.arxivId != arxivId).toList(),
      ));
      _persistSession();
    }
  }

  void _addMessage(Message msg) {
    if (_messages.length >= AppConstants.maxChatMessages) {
      _messages.removeAt(0);
    }
    _messages.add(msg);
    _session = _session.copyWith(
      messages: List.from(_messages),
      updatedAt: DateTime.now(),
    );
  }

  void _persistSession() {
    _chatRepository.saveSession(_session);
  }
}
