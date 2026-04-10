import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final String expertiseLevel;
  final bool isDarkMode;
  final bool isLoading;

  const SettingsState({
    this.expertiseLevel = 'intermediate',
    this.isDarkMode = false,
    this.isLoading = false,
  });

  SettingsState copyWith({String? expertiseLevel, bool? isDarkMode, bool? isLoading}) {
    return SettingsState(
      expertiseLevel: expertiseLevel ?? this.expertiseLevel,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [expertiseLevel, isDarkMode, isLoading];
}
