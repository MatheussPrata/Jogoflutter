import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/user.dart';

class AuthService {
  static const _userKey = 'flutter_quest_user';
  static const _sessionKey = 'flutter_quest_session';

  final SharedPreferences _prefs;

  AuthService(this._prefs);

  String _generateSalt() {
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    return sha256.convert(utf8.encode(random)).toString().substring(0, 16);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    return sha256.convert(bytes).toString();
  }

  Future<User> register(String username, String email, String password) async {
    final salt = _generateSalt();
    final passwordHash = _hashPassword(password, salt);
    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      email: email,
      passwordHash: passwordHash,
      salt: salt,
      xp: 0,
      createdAt: DateTime.now(),
    );
    await _saveUser(user);
    return user;
  }

  Future<User?> login(String email, String password) async {
    final user = _getStoredUser();
    if (user == null) return null;
    if (user.email != email) return null;
    final hash = _hashPassword(password, user.salt);
    if (hash != user.passwordHash) return null;
    return user;
  }

  Future<void> _saveUser(User user) async {
    final json = jsonEncode(user.toJson());
    await _prefs.setString(_userKey, json);
  }

  User? _getStoredUser() {
    final json = _prefs.getString(_userKey);
    if (json == null) return null;
    return User.fromJson(jsonDecode(json));
  }

  Future<void> saveSession(User user) async {
    final json = jsonEncode(user.toJson());
    await _prefs.setString(_sessionKey, json);
  }

  Future<User?> getSession() async {
    final json = _prefs.getString(_sessionKey);
    if (json == null) return null;
    return User.fromJson(jsonDecode(json));
  }

  Future<void> clearSession() async {
    await _prefs.remove(_sessionKey);
  }

  Future<void> logout() async {
    await clearSession();
  }
}