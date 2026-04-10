import 'package:hive/hive.dart';
import '../../../core/constants/hive_keys.dart';
import '../../models/chat_session_model.dart';
import '../../models/paper_model.dart';

class SettingsLocalDatasource {
  Box get _box => Hive.box(HiveKeys.settingsBox);

  Future<void> setExpertiseLevel(String level) async {
    await _box.put('expertise_level', level);
  }

  String getExpertiseLevel() => _box.get('expertise_level', defaultValue: 'intermediate') as String;

  Future<void> setDarkMode(bool enabled) async {
    await _box.put('dark_mode', enabled);
  }

  bool getDarkMode() => _box.get('dark_mode', defaultValue: false) as bool;

  Future<void> clearAllData() async {
    await _box.clear();
    await Hive.box<ChatSessionModel>(HiveKeys.chatSessionsBox).clear();
    await Hive.box<PaperModel>(HiveKeys.papersBox).clear();
  }
}
