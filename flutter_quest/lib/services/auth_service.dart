import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String _usersKey = 'flutter_quest_users';
  static const String _currentUserKey = 'flutter_quest_current_user';

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_usersKey)) {
      await prefs.setString(_usersKey, '[]');
    }
  }

  Future<List<User>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey) ?? '[]';
    final List<dynamic> usersList = json.decode(usersJson);
    return usersList.map((json) => User.fromJson(json)).toList();
  }

  Future<void> _saveUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = json.encode(users.map((u) => u.toJson()).toList());
    await prefs.setString(_usersKey, usersJson);
  }

  Future<AuthResult> register({
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    await initialize();

    if (email.isEmpty || username.isEmpty || password.isEmpty) {
      return AuthResult.error('Todos os campos são obrigatórios');
    }

    if (!email.contains('@')) {
      return AuthResult.error('Email inválido');
    }

    if (password.length < 6) {
      return AuthResult.error('A senha deve ter pelo menos 6 caracteres');
    }

    if (password != confirmPassword) {
      return AuthResult.error('As senhas não coincidem');
    }

    final users = await _getUsers();

    if (users.any((u) => u.email == email.toLowerCase().trim())) {
      return AuthResult.error('Este email já está cadastrado');
    }

    if (users.any((u) => u.username == username.trim())) {
      return AuthResult.error('Este nome de usuário já está em uso');
    }

    final newUser = User.create(
      email: email,
      username: username,
      password: password,
    );

    users.add(newUser);
    await _saveUsers(users);
    await _setCurrentUser(newUser);

    return AuthResult.success(newUser);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    await initialize();

    if (email.isEmpty || password.isEmpty) {
      return AuthResult.error('Email e senha são obrigatórios');
    }

    final users = await _getUsers();
    final user = users.firstWhere(
      (u) => u.email == email.toLowerCase().trim(),
      orElse: () => User(
        id: '',
        email: '',
        username: '',
        passwordHash: '',
        createdAt: DateTime.now(),
      ),
    );

    if (user.id.isEmpty || !user.verifyPassword(password)) {
      return AuthResult.error('Email ou senha inválidos');
    }

    await _setCurrentUser(user);
    return AuthResult.success(user);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);
    if (userJson == null) return null;
    return User.fromJson(json.decode(userJson));
  }

  Future<void> _setCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, json.encode(user.toJson()));
  }

  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }
}

class AuthResult {
  final bool success;
  final String? error;
  final User? user;

  AuthResult._({required this.success, this.error, this.user});

  factory AuthResult.success(User user) => AuthResult._(success: true, user: user);
  factory AuthResult.error(String error) => AuthResult._(success: false, error: error);
}