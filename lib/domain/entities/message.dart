import 'package:equatable/equatable.dart';

class Citation extends Equatable {
  final String paperTitle;
  final int pageNumber;
  final String chunkText;

  const Citation({
    required this.paperTitle,
    required this.pageNumber,
    required this.chunkText,
  });

  @override
  List<Object?> get props => [paperTitle, pageNumber, chunkText];
}

class Message extends Equatable {
  final String messageId;
  final String role; // 'user' | 'assistant'
  final String content;
  final List<Citation>? citations;
  final DateTime timestamp;
  final String? slashCommand;

  const Message({
    required this.messageId,
    required this.role,
    required this.content,
    this.citations,
    required this.timestamp,
    this.slashCommand,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  @override
  List<Object?> get props => [messageId, role, content, citations, timestamp, slashCommand];
}
