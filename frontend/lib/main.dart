
// File Name: main.dart
// Description: Application entry point and root configuration for Auxilia.
// Author: Keefe Chen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/welcome_screen.dart';
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
  const AuxiliaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Auxilia',
      debugShowCheckedModeBanner: false,
      theme: AuxiliaTheme.light(),
      darkTheme: AuxiliaTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}

