import 'package:dartz/dartz.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';
import '../../core/network/api_exceptions.dart';

const _validCommands = {
  'summary', 'compare', 'review', 'gaps', 'code', 'visualize', 'search', 'explain'
};

class ProcessSlashCommand {
  final ChatRepository repository;
  ProcessSlashCommand(this.repository);

  Future<Either<Failure, Message>> call({
    required String rawCommand,
    required List<String> paperIds,
    required Map<String, String> paperTitles,
    String? sessionId,
  }) {
    final parts = rawCommand.trimLeft().replaceFirst('/', '').split(' ');
    final command = parts.first.toLowerCase();
    final argument = parts.length > 1 ? parts.sublist(1).join(' ') : null;

    if (!_validCommands.contains(command)) {
      return Future.value(Left(ValidationFailure('Unknown command: /$command')));
    }

    return repository.executeSlashCommand(
      command: '/$command',
      argument: argument,
      paperIds: paperIds,
      paperTitles: paperTitles,
      sessionId: sessionId,
    );
  }
}
