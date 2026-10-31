
// File Name: main.dart
// Description: Application entry point and root configuration for Auxilia.
// Author: Keefe Chen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'routing/app_router.dart';
import 'screens/startup_gate.dart';
import 'services/auth_service.dart';
import 'services/task_store.dart';
import 'theme/app_theme.dart';

// Application navigation configuration
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const WelcomeScreen(),
    ),
  ],
);

void main() {
  runApp(
    const ProviderScope(
      child: AuxiliaApp(),
    ),
  );
}

class AuxiliaApp extends StatelessWidget {
  const AuxiliaApp({super.key, this.auth, this.store});

  final AuthService? auth;
  final TaskStore? store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Auxilia',
      debugShowCheckedModeBanner: false,
      theme: AuxiliaTheme.light(),
      darkTheme: AuxiliaTheme.dark(),
      themeMode: ThemeMode.system,
<<<<<<< HEAD
      routerConfig: appRouter,
=======
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: StartupGate(auth: auth, store: store),
>>>>>>> da0726bcb826a09906dd470d62c2be4b695dbe25
    );
  }
}

