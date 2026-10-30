import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionException implements Exception {
  SessionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class Session {
  const Session({required this.token, required this.email, this.name});

  final String token;
  final String email;
  final String? name;

  String get displayName {
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return email;
    return trimmed;
  }

  factory Session.fromApi(Map<String, dynamic> data) {
    final token = data['token'];
    final user = data['user'];
    if (token is! String || token.isEmpty || user is! Map) {
      throw SessionException(
        'The server returned an incomplete sign-in response.',
      );
    }

    final email = user['email'];
    if (email is! String || email.isEmpty) {
      throw SessionException(
        'The server returned an incomplete sign-in response.',
      );
    }

    final name = user['name'];
    return Session(
      token: token,
      email: email,
      name: name is String ? name : null,
    );
  }
}

/// Stores the session token in platform secure storage rather than plain
/// preferences or source code.
class SessionStore {
  SessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'auxilia.session.token';
  static const String _emailKey = 'auxilia.session.email';
  static const String _nameKey = 'auxilia.session.name';

  final FlutterSecureStorage _storage;

  Future<Session?> read() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      final email = await _storage.read(key: _emailKey);
      if (token == null || token.isEmpty || email == null || email.isEmpty) {
        return null;
      }
      final name = await _storage.read(key: _nameKey);
      return Session(token: token, email: email, name: name);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(Session session) async {
    try {
      await _storage.write(key: _tokenKey, value: session.token);
      await _storage.write(key: _emailKey, value: session.email);
      if (session.name == null) {
        await _storage.delete(key: _nameKey);
      } else {
        await _storage.write(key: _nameKey, value: session.name);
      }
    } catch (_) {
      throw SessionException(
        'Signed in, but the session could not be stored securely on this device.',
      );
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _emailKey);
      await _storage.delete(key: _nameKey);
    } catch (_) {
      throw SessionException(
        'The session could not be removed from this device.',
      );
    }
  }
}
