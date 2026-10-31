import 'package:flutter/material.dart';

import 'routing/app_router.dart';
import 'screens/startup_gate.dart';
import 'services/auth_service.dart';
import 'services/task_store.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const AuxiliaApp());
}

class AuxiliaApp extends StatelessWidget {
  const AuxiliaApp({super.key, this.auth, this.store});

  final AuthService? auth;
  final TaskStore? store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auxilia',
      debugShowCheckedModeBanner: false,
      theme: AuxiliaTheme.light(),
      darkTheme: AuxiliaTheme.dark(),
      themeMode: ThemeMode.system,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: StartupGate(auth: auth, store: store),
    );
  }
}
