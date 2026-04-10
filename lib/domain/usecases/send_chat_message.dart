import 'package:dartz/dartz.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';
import '../../core/network/api_exceptions.dart';

class SendChatMessage {
  final ChatRepository repository;
  SendChatMessage(this.repository);

  Future<Either<Failure, Message>> call({
    required String question,
    required List<String> paperIds,
    required Map<String, String> paperTitles,
    String? sessionId,
    String? expertiseLevel,
  }) {
    return repository.sendChatQuery(
      question: question,
      paperIds: paperIds,
      paperTitles: paperTitles,
      sessionId: sessionId,
      expertiseLevel: expertiseLevel,
    );
  }
}
