import 'dart:convert';
import 'package:crypto/crypto.dart';

class User {
  final String id;
  final String email;
  final String username;
  final String passwordHash;
  final DateTime createdAt;
  final int xp;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.passwordHash,
    required this.createdAt,
    this.xp = 0,
  });

  factory User.create({
    required String email,
    required String username,
    required String password,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final passwordHash = _hashPassword(password);
    return User(
      id: id,
      email: email.toLowerCase().trim(),
      username: username.trim(),
      passwordHash: passwordHash,
      createdAt: DateTime.now(),
    );
  }

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'flutter_quest_salt_2024');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool verifyPassword(String password) {
    final hashed = _hashPassword(password);
    return hashed == passwordHash;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'passwordHash': passwordHash,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      passwordHash: json['passwordHash'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}