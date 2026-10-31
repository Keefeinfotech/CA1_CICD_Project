import 'package:flutter/material.dart';

import '../routing/app_router.dart';
import '../services/auth_service.dart';
import '../services/session_store.dart';
import '../theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.auth});

  final AuthService? auth;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final AuthService _auth = widget.auth ?? AuthService();

  Future<void> _openAssistant() async {
    final Session? session;
    try {
      session = await _auth.restore();
    } on SessionException {
      if (mounted) {
        _showMessage(
          'Your saved session could not be read. Please sign in again.',
        );
      }
      return;
    }

    if (!mounted) return;

    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sign in to use the AI assistant.'),
          action: SnackBarAction(label: 'Sign in', onPressed: _openLogin),
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.assistant,
      arguments: AssistantArgs(session: session),
    );
  }

  void _openLogin() {
    Navigator.pushNamed(context, AppRoutes.login);
  }

  void _openSignup() {
    Navigator.pushNamed(context, AppRoutes.signup);
  }

  void _continueOffline() {
    Navigator.pushNamed(
      context,
      AppRoutes.home,
      arguments: const HomeArgs(ownerId: 'local'),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AuxiliaColors.brandGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.assistant, size: 80, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'Auxilia',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Your personal secretary, on your device',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: <Widget>[
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _continueOffline,
                              icon: const Icon(Icons.dashboard_outlined),
                              label: const Text('Open my tasks'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tasks are stored on this device and work offline.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                          const Divider(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _openLogin,
                              icon: const Icon(Icons.login),
                              label: const Text('Log in'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _openSignup,
                              icon: const Icon(Icons.person_add_alt_1),
                              label: const Text('Sign up'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _openAssistant,
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Try the AI assistant'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
