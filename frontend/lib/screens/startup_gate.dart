import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/session_store.dart';
import '../services/task_store.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

/// Restores the securely stored session once at launch so signed-in students
/// land on their dashboard instead of repeating the login flow.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key, this.auth, this.store});

  final AuthService? auth;
  final TaskStore? store;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late final AuthService _auth = widget.auth ?? AuthService();
  Session? _session;
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    Session? session;
    try {
      session = await _auth.restore().timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
    } on SessionException {
      session = null;
    }
    if (!mounted) return;
    setState(() {
      _session = session;
      _restored = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_restored) return const _SplashView();

    final session = _session;
    if (session == null) return const WelcomeScreen();

    return HomeScreen(
      ownerId: session.email,
      displayName: session.displayName,
      session: session,
      store: widget.store,
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AuxiliaColors.brandGradient),
        child: const SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.assistant, size: 64, color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Auxilia',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Restoring your workspace...',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
