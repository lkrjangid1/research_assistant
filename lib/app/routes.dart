import 'package:flutter/material.dart';
import '../domain/entities/paper.dart';
import '../presentation/pages/search/search_page.dart';
import '../presentation/pages/paper_details/paper_details_page.dart';
import '../presentation/pages/chat/chat_page.dart';
import '../presentation/pages/settings/settings_page.dart';

class AppRoutes {
  static const String search = '/';
  static const String paperDetails = '/paper-details';
  static const String chat = '/chat';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.search:
        return MaterialPageRoute(builder: (_) => const SearchPage());
      case AppRoutes.paperDetails:
        final paper = settings.arguments as Paper;
        return MaterialPageRoute(builder: (_) => PaperDetailsPage(paper: paper));
      case AppRoutes.chat:
        return MaterialPageRoute(builder: (_) => const ChatPage());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      default:
        return MaterialPageRoute(builder: (_) => const SearchPage());
    }
  }
}
