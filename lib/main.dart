import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/hive_keys.dart';
import 'core/di/injection_container.dart';
import 'data/models/paper_model.dart';
import 'data/models/chat_session_model.dart';
import 'data/models/message_model.dart';
import 'data/models/citation_model.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(PaperModelAdapter());
  Hive.registerAdapter(ChatSessionModelAdapter());
  Hive.registerAdapter(MessageModelAdapter());
  Hive.registerAdapter(CitationModelAdapter());
  await Future.wait([
    Hive.openBox<PaperModel>(HiveKeys.papersBox),
    Hive.openBox<ChatSessionModel>(HiveKeys.chatSessionsBox),
    Hive.openBox(HiveKeys.settingsBox),
  ]);
  await initDependencies();
  runApp(const ResearchAssistantApp());
}
