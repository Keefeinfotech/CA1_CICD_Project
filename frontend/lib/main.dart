import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const AuxiliaApp());
}

class AuxiliaApp extends StatelessWidget {
  const AuxiliaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auxilia',
      debugShowCheckedModeBanner: false,
      theme: AuxiliaTheme.light(),
      darkTheme: AuxiliaTheme.dark(),
      themeMode: ThemeMode.system,
      home: const WelcomeScreen(),
    );
  }
}
