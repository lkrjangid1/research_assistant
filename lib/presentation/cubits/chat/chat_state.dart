import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_session.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/entities/paper.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatSessionLoaded extends ChatState {
  final ChatSession session;
  final List<Message> messages;
  final List<Paper> sessionPapers;
  final bool isProcessing;
  // True when session was resumed from history (papers already indexed on backend)
  final bool isResumedSession;

  const ChatSessionLoaded({
    required this.session,
    required this.messages,
    this.sessionPapers = const [],
    this.isProcessing = false,
    this.isResumedSession = false,
  });

  ChatSessionLoaded copyWith({
    List<Message>? messages,
    List<Paper>? sessionPapers,
    bool? isProcessing,
  }) {
    return ChatSessionLoaded(
      session: session,
      messages: messages ?? this.messages,
      sessionPapers: sessionPapers ?? this.sessionPapers,
      isProcessing: isProcessing ?? this.isProcessing,
      isResumedSession: isResumedSession,
    );
  }

  @override
  List<Object?> get props => [session, messages, sessionPapers, isProcessing, isResumedSession];
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);
  @override
  List<Object?> get props => [message];
}
