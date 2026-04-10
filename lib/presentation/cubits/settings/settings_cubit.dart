import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/local/settings_local_datasource.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsLocalDatasource _ds;

  SettingsCubit(this._ds) : super(const SettingsState());

  void loadSettings() {
    emit(SettingsState(
      expertiseLevel: _ds.getExpertiseLevel(),
      isDarkMode: _ds.getDarkMode(),
    ));
  }

  Future<void> setExpertiseLevel(String level) async {
    await _ds.setExpertiseLevel(level);
    emit(state.copyWith(expertiseLevel: level));
  }

  Future<void> toggleDarkMode() async {
    final next = !state.isDarkMode;
    await _ds.setDarkMode(next);
    emit(state.copyWith(isDarkMode: next));
  }

  Future<void> clearAllData() async {
    emit(state.copyWith(isLoading: true));
    await _ds.clearAllData();
    emit(const SettingsState());
  }
}
