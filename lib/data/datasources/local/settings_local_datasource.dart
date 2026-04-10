import 'package:hive/hive.dart';
import '../../../core/constants/hive_keys.dart';

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
    final chatBox = Hive.box(HiveKeys.chatSessionsBox);
    await chatBox.clear();
    final papersBox = Hive.box(HiveKeys.papersBox);
    await papersBox.clear();
  }
}
