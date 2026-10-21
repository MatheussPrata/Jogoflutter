import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Registo persistido de utilizador (com hash+salt, nunca a senha em claro).
class UserRecord {
  final String id;
  final String username;
  final String email;
  final String passwordHash;
  final String salt;
  final int xp;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserRecord({
    required this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.xp,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toStorageJson() => {
        'id': id,
        'username': username,
        'email': email,
        'passwordHash': passwordHash,
        'salt': salt,
        'xp': xp,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory UserRecord.fromStorageJson(Map<String, dynamic> json) => UserRecord(
        id: json['id'] as String,
        username: json['username'] as String,
        email: json['email'] as String,
        passwordHash: json['passwordHash'] as String,
        salt: json['salt'] as String,
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(
          (json['updatedAt'] ?? json['createdAt']) as String,
        ),
      );

  /// Resposta pública: sem passwordHash nem salt.
  Map<String, dynamic> toPublicJson() => {
        'id': id,
        'username': username,
        'email': email,
        'xp': xp,
        'createdAt': createdAt.toIso8601String(),
      };

  UserRecord copyWith({
    String? username,
    String? email,
    String? passwordHash,
    String? salt,
    int? xp,
  }) {
    return UserRecord(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      xp: xp ?? this.xp,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
  }
}

/// Salt/hash partilhados com o AuthService do cliente
/// (SHA-256 sobre `password + salt`, salt de 16 chars hex).
class PasswordHasher {
  static final _random = Random.secure();

  static String generateSalt() {
    final buffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      buffer.write(_random.nextInt(16).toRadixString(16));
    }
    return buffer.toString();
  }

  static String hash(String password, String salt) {
    return sha256.convert(utf8.encode(password + salt)).toString();
  }

  /// Comparação em tempo constante para mitigar timing attacks.
  static bool safeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
