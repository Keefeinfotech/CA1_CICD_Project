import 'package:flutter/material.dart';

import '../screens/ai_chat_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/welcome_screen.dart';
import '../services/session_store.dart';

/// Named routes keep navigation, arguments and back-stack behaviour in one
/// place instead of duplicating MaterialPageRoute construction in screens.
abstract final class AppRoutes {
  static const String startup = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String assistant = '/assistant';
}

class HomeArgs {
  const HomeArgs({required this.ownerId, this.displayName, this.session});

  final String ownerId;
  final String? displayName;
  final Session? session;
}

class AssistantArgs {
  const AssistantArgs({required this.session});

  final Session session;
}

class AppRouter {
  const AppRouter._();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.welcome:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const WelcomeScreen(),
        );
      case AppRoutes.login:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );
      case AppRoutes.signup:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SignupScreen(),
        );
      case AppRoutes.home:
        final args = settings.arguments;
        if (args is! HomeArgs) return null;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => HomeScreen(
            ownerId: args.ownerId,
            displayName: args.displayName,
            session: args.session,
          ),
        );
      case AppRoutes.assistant:
        final args = settings.arguments;
        if (args is! AssistantArgs) return null;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => AiChatScreen(session: args.session),
        );
      default:
        return null;
    }
  }
}
