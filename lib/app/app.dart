import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/di/injection_container.dart';
import '../core/theme/app_theme.dart';
import '../presentation/cubits/paper_selection/paper_selection_cubit.dart';
import '../presentation/cubits/settings/settings_cubit.dart';
import '../presentation/cubits/settings/settings_state.dart';
import 'routes.dart';

class ResearchAssistantApp extends StatelessWidget {
  const ResearchAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PaperSelectionCubit>(create: (_) => sl<PaperSelectionCubit>()),
        BlocProvider<SettingsCubit>(create: (_) => sl<SettingsCubit>()..loadSettings()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          return MaterialApp(
            title: 'Research Assistant',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            initialRoute: AppRoutes.search,
          );
        },
      ),
    );
  }
}
