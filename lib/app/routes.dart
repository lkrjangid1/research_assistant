import 'package:flutter/material.dart';
import '../domain/entities/paper.dart';
import '../presentation/pages/search/search_page.dart';
import '../presentation/pages/paper_details/paper_details_page.dart';
import '../presentation/pages/chat/chat_page.dart';
import '../presentation/pages/chat_history/chat_history_page.dart';
import '../presentation/pages/settings/settings_page.dart';

/// Optional args for the chat route.
/// If [sessionId] is set the ChatPage will resume that session instead of
/// creating a new one from the current paper selection.
class ChatRouteArgs {
  final String? sessionId;
  const ChatRouteArgs({this.sessionId});
}

class AppRoutes {
  static const String search = '/';
  static const String paperDetails = '/paper-details';
  static const String chat = '/chat';
  static const String chatHistory = '/chat-history';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.search:
        return MaterialPageRoute(builder: (_) => const SearchPage());
      case AppRoutes.paperDetails:
        final paper = settings.arguments as Paper;
        return MaterialPageRoute(builder: (_) => PaperDetailsPage(paper: paper));
      case AppRoutes.chat:
        final args = settings.arguments is ChatRouteArgs
            ? settings.arguments as ChatRouteArgs
            : null;
        return MaterialPageRoute(
            builder: (_) => ChatPage(sessionId: args?.sessionId));
      case AppRoutes.chatHistory:
        return MaterialPageRoute(builder: (_) => const ChatHistoryPage());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      default:
        return MaterialPageRoute(builder: (_) => const SearchPage());
    }
  }
}
