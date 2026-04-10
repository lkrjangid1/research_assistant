import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_session.dart';

abstract class ChatHistoryState extends Equatable {
  const ChatHistoryState();
  @override
  List<Object?> get props => [];
}

class ChatHistoryInitial extends ChatHistoryState {
  const ChatHistoryInitial();
}

class ChatHistoryLoaded extends ChatHistoryState {
  final List<ChatSession> sessions;

  const ChatHistoryLoaded(this.sessions);

  @override
  List<Object?> get props => [sessions];
}

class ChatHistoryEmpty extends ChatHistoryState {
  const ChatHistoryEmpty();
}
