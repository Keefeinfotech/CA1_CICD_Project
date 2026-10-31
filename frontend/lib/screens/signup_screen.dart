import 'package:flutter/material.dart';

import '../routing/app_router.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/session_store.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, this.auth});

  final AuthService? auth;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  late final AuthService _auth = widget.auth ?? AuthService();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final session = await _auth.signup(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.home,
        arguments: HomeArgs(
          ownerId: session.email,
          displayName: session.displayName,
          session: session,
        ),
      );
    } on ApiException catch (err) {
      if (mounted) _showError(err.message);
    } on SessionException catch (err) {
      if (mounted) _showError(err.message);
    } catch (_) {
      if (mounted) {
        _showError('Something went wrong while creating your account.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.person_add_outlined,
                        size: 48,
                        color: Colors.indigo,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Name (optional)',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().length > 80) {
                            return 'Keep your name under 80 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const <String>[AutofillHints.email],
                        validator: (value) {
                          final email = (value ?? '').trim();
                          if (email.isEmpty) return 'Enter your email';
                          if (!email.contains('@')) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        decoration: const InputDecoration(
                          labelText: 'Password (min 8)',
                          prefixIcon: Icon(Icons.lock_outlined),
                        ),
                        obscureText: true,
                        autofillHints: const <String>[
                          AutofillHints.newPassword,
                        ],
                        validator: (value) {
                          if (value == null || value.length < 8) {
                            return 'Use at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : _signup,
                          child: Text(_loading ? 'Signing up...' : 'Sign Up'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
