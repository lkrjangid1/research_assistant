import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_session.dart';
import '../../../domain/entities/message.dart';

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
  final bool isProcessing;

  const ChatSessionLoaded({
    required this.session,
    required this.messages,
    this.isProcessing = false,
  });

  ChatSessionLoaded copyWith({List<Message>? messages, bool? isProcessing}) {
    return ChatSessionLoaded(
      session: session,
      messages: messages ?? this.messages,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  @override
  List<Object?> get props => [session, messages, isProcessing];
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);
  @override
  List<Object?> get props => [message];
}
