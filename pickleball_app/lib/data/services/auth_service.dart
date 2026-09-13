import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

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

  Map<String, dynamic> toJson() => {'id': id, 'email': email};
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _loadPersistedSession();
  }

  String get baseUrl => ApiConfig.baseUrl;

  String? _accessToken;
  UserProfile? _user;
  bool _isInitialized = false;

  String? get accessToken => _accessToken;
  UserProfile? get currentUser => _user;
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;
  bool get isInitialized => _isInitialized;

  Future<void> _loadPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
      final userJson = prefs.getString('user_profile');
      if (userJson != null) {
        _user = UserProfile.fromJson(jsonDecode(userJson));
      }
    } catch (e) {
      if (kDebugMode) print('Failed to load session: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _saveSession(String token, UserProfile user) async {
    _accessToken = token;
    _user = user;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await prefs.setString('user_profile', jsonEncode(user.toJson()));
    } catch (e) {
      if (kDebugMode) print('Failed to persist session: $e');
    }
  }

  Future<void> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      final user = UserProfile.fromJson(data['user']);
      await _saveSession(token, user);
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
      final token = data['access_token'];
      final user = UserProfile.fromJson(data['user']);
      await _saveSession(token, user);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Login failed');
    }
  }

  Future<void> signOut() async {
    _accessToken = null;
    _user = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('user_profile');
    } catch (e) {
      if (kDebugMode) print('Failed to clear session: $e');
    }
  }
}
