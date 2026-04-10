import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/chat_repository.dart';
import 'chat_history_state.dart';

class ChatHistoryCubit extends Cubit<ChatHistoryState> {
  final ChatRepository _chatRepository;

  ChatHistoryCubit(this._chatRepository) : super(const ChatHistoryInitial());

  Future<void> loadSessions() async {
    final result = await _chatRepository.getAllSessions();
    result.fold(
      (_) => emit(const ChatHistoryEmpty()),
      (sessions) {
        if (sessions.isEmpty) {
          emit(const ChatHistoryEmpty());
        } else {
          emit(ChatHistoryLoaded(sessions));
        }
      },
    );
  }

  Future<void> deleteSession(String sessionId) async {
    await _chatRepository.deleteSession(sessionId);
    await loadSessions();
  }
}
