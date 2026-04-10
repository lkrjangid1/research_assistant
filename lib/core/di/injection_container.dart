import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../../data/datasources/remote/arxiv_api_service.dart';
import '../../data/datasources/remote/backend_api_service.dart';
import '../../data/datasources/local/chat_local_datasource.dart';
import '../../data/datasources/local/settings_local_datasource.dart';
import '../../data/repositories/paper_repository_impl.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/repositories/paper_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/search_papers.dart';
import '../../domain/usecases/get_paper_summary.dart';
import '../../domain/usecases/send_chat_message.dart';
import '../../domain/usecases/process_slash_command.dart';
import '../../presentation/cubits/search/search_cubit.dart';
import '../../presentation/cubits/paper_selection/paper_selection_cubit.dart';
import '../../presentation/cubits/paper_details/paper_details_cubit.dart';
import '../../presentation/cubits/chat/chat_cubit.dart';
import '../../presentation/cubits/settings/settings_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ── Network ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<Dio>(() => createBackendDio(), instanceName: 'backend');
  sl.registerLazySingleton<Dio>(() => createArxivDio(), instanceName: 'arxiv');

  // ── Remote datasources ─────────────────────────────────────────────────────
  sl.registerLazySingleton(() => ArxivApiService(sl<Dio>(instanceName: 'arxiv')));
  sl.registerLazySingleton(() => BackendApiService(sl<Dio>(instanceName: 'backend')));

  // ── Local datasources ──────────────────────────────────────────────────────
  sl.registerLazySingleton(() => ChatLocalDatasource());
  sl.registerLazySingleton(() => SettingsLocalDatasource());

  // ── Repositories ───────────────────────────────────────────────────────────
  sl.registerLazySingleton<PaperRepository>(
    () => PaperRepositoryImpl(sl<ArxivApiService>(), sl<BackendApiService>()),
  );
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(sl<BackendApiService>(), sl<ChatLocalDatasource>()),
  );

  // ── Use cases ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => SearchPapers(sl<PaperRepository>()));
  sl.registerLazySingleton(() => GetPaperSummary(sl<PaperRepository>()));
  sl.registerLazySingleton(() => SendChatMessage(sl<ChatRepository>()));
  sl.registerLazySingleton(() => ProcessSlashCommand(sl<ChatRepository>()));

  // ── Cubits (factories — new instance per page) ─────────────────────────────
  sl.registerFactory(() => SearchCubit(sl<SearchPapers>()));
  sl.registerFactory(() => PaperDetailsCubit(sl<GetPaperSummary>()));
  sl.registerFactory(() => ChatCubit(
        sl<SendChatMessage>(),
        sl<ProcessSlashCommand>(),
        sl<ChatRepository>(),
      ));

  // ── Global cubits (singletons) ─────────────────────────────────────────────
  sl.registerLazySingleton(() => PaperSelectionCubit(sl<PaperRepository>()));
  sl.registerLazySingleton(() => SettingsCubit(sl<SettingsLocalDatasource>()));
}
