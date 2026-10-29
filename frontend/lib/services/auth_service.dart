import 'dart:convert';
import 'package:http/http.dart' as http;

// Simple auth service - replace baseUrl with your backend URL
class AuthService {
  static const String baseUrl = 'http://localhost:3000';

  Future<Map<String, dynamic>> signup({
    String? name,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/signup');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (name != null && name.isNotEmpty) 'name': name,
        'email': email,
        'password': password,
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
