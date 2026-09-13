import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class UserProfile {
  final String id;
  final String email;

  UserProfile({required this.id, required this.email});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final String baseUrl = 'http://localhost:8000'; // Change to http://10.0.2.2:8000 for Android Emulator

  String? _accessToken;
  UserProfile? _user;

  String? get accessToken => _accessToken;
  UserProfile? get currentUser => _user;
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  Future<void> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
      _user = UserProfile.fromJson(data['user']);
      notifyListeners();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Registration failed');
    }
  }

  Future<void> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
      _user = UserProfile.fromJson(data['user']);
      notifyListeners();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Login failed');
    }
  }

  void signOut() {
    _accessToken = null;
    _user = null;
    notifyListeners();
  }
}
