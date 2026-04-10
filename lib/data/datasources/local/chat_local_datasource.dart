import 'package:hive/hive.dart';
import '../../models/chat_session_model.dart';
import '../../../core/constants/hive_keys.dart';

class ChatLocalDatasource {
  Box<ChatSessionModel> get _box => Hive.box<ChatSessionModel>(HiveKeys.chatSessionsBox);

  Future<void> saveSession(ChatSessionModel session) async {
    await _box.put(session.sessionId, session);
  }

  ChatSessionModel? getSession(String sessionId) => _box.get(sessionId);

  List<ChatSessionModel> getAllSessions() =>
      _box.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Future<void> deleteSession(String sessionId) async {
    await _box.delete(sessionId);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
