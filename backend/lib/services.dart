import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'store.dart';
import 'user_record.dart';

/// Tokens opacos de sessão persistidos em disco (sobrevivem a restart).
class TokenService {
  static const int tokenTtlDays = 30;
  static final _random = Random.secure();

  final JsonStore store;

  TokenService(this.store);

  static String _generateToken() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  Future<String> issue(String userId) async {
    final token = _generateToken();
    final expiresAt = DateTime.now().toUtc().add(
          const Duration(days: tokenTtlDays),
        );
    await store.mutateList('sessions', (items) async {
      items.add({
        'token': token,
        'userId': userId,
        'expiresAt': expiresAt.toIso8601String(),
      });
      return null;
    });
    return token;
  }

  Future<String?> userIdFor(String? token) async {
    if (token == null || token.isEmpty) return null;
    final items = await store.readList('sessions');
    final now = DateTime.now().toUtc();
    for (final raw in items) {
      if (raw is! Map<String, dynamic>) continue;
      if (raw['token'] != token) continue;
      final expiresAt = DateTime.tryParse(raw['expiresAt'] as String? ?? '');
      if (expiresAt == null || expiresAt.isBefore(now)) return null;
      return raw['userId'] as String?;
    }
    return null;
  }

  Future<void> revoke(String token) async {
    await store.mutateList('sessions', (items) async {
      items.removeWhere(
        (e) => e is Map<String, dynamic> && e['token'] == token,
      );
      return null;
    });
  }

  /// Remove sessões expiradas (chamado no arranque).
  Future<int> purgeExpired() async {
    final now = DateTime.now().toUtc();
    return store.mutateList<int>('sessions', (items) async {
      final before = items.length;
      items.removeWhere((e) {
        if (e is! Map<String, dynamic>) return true;
        final expiresAt = DateTime.tryParse(e['expiresAt'] as String? ?? '');
        return expiresAt == null || expiresAt.isBefore(now);
      });
      return before - items.length;
    });
  }
}

/// Regras de negócio de utilizadores.
class UserService {
  final JsonStore store;

  UserService(this.store);

  Future<Map<String, dynamic>> _users() async {
    return store.readMap('users');
  }

  Future<UserRecord?> findByEmail(String email) async {
    final users = await _users();
    final normalized = email.trim().toLowerCase();
    for (final entry in users.entries) {
      final record = _decode(entry.key, entry.value);
      if (record != null && record.email.toLowerCase() == normalized) {
        return record;
      }
    }
    return null;
  }

  Future<UserRecord?> findById(String id) async {
    final users = await _users();
    final raw = users[id];
    if (raw is! Map<String, dynamic>) return null;
    return UserRecord.fromStorageJson(raw);
  }

  UserRecord? _decode(String id, dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    try {
      return UserRecord.fromStorageJson(raw);
    } on Object {
      return null;
    }
  }

  Future<UserRecord> create({
    required String username,
    required String email,
    required String password,
    bool isAdmin = false,
  }) async {
    final salt = PasswordHasher.generateSalt();
    final now = DateTime.now().toUtc();
    final record = UserRecord(
      id: 'u_${now.microsecondsSinceEpoch}_${PasswordHasher.generateSalt()}',
      username: username.trim(),
      email: email.trim(),
      passwordHash: PasswordHasher.hash(password, salt),
      salt: salt,
      xp: 0,
      createdAt: now,
      updatedAt: now,
      isAdmin: isAdmin,
    );
    final users = await _users();
    users[record.id] = record.toStorageJson();
    await store.writeMap('users', users);
    return record;
  }

  Future<void> save(UserRecord record) async {
    final users = await _users();
    users[record.id] = record.toStorageJson();
    await store.writeMap('users', users);
  }

  /// Devolve o registo se a senha confere; null caso contrário.
  Future<UserRecord?> verify(UserRecord user, String password) async {
    final candidate = PasswordHasher.hash(password, user.salt);
    if (!PasswordHasher.safeEquals(candidate, user.passwordHash)) return null;
    return user;
  }

  Future<int> count() async => (await _users()).length;
}

/// Exceção de API com código HTTP e mensagem pública.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  Map<String, dynamic> toJson() => {'error': message};
  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Validações partilhadas pelos endpoints.
class Validators {
  static final _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static void requireString(
    Map<String, dynamic> body,
    String field, {
    int min = 1,
    int max = 200,
  }) {
    final value = body[field];
    if (value is! String || value.trim().isEmpty) {
      throw ApiException(400, 'Campo "$field" é obrigatório.');
    }
    if (value.trim().length < min) {
      throw ApiException(400, 'Campo "$field" deve ter pelo menos $min caracteres.');
    }
    if (value.length > max) {
      throw ApiException(400, 'Campo "$field" excede $max caracteres.');
    }
  }

  static void requireEmail(Map<String, dynamic> body) {
    requireString(body, 'email', max: 254);
    if (!_email.hasMatch((body['email'] as String).trim())) {
      throw ApiException(400, 'Email inválido.');
    }
  }

  static void requirePassword(Map<String, dynamic> body, {int min = 6}) {
    requireString(body, 'password', min: min, max: 128);
  }

  static double requireAmount(Map<String, dynamic> body) {
    final raw = body['amount'];
    final value = raw is num ? raw.toDouble() : double.tryParse('$raw');
    if (value == null || value.isNaN || value.isInfinite || value <= 0) {
      throw ApiException(400, 'Valor deve ser um número positivo.');
    }
    return value;
  }

  static String requireEnum(
    Map<String, dynamic> body,
    String field,
    List<String> allowed,
  ) {
    final value = body[field];
    if (value is! String || !allowed.contains(value)) {
      throw ApiException(400, 'Campo "$field" deve ser um de: ${allowed.join(', ')}.');
    }
    return value;
  }
}

/// Utilitário para ler corpo JSON de um request.
Future<Map<String, dynamic>> readJsonBody(Stream<List<int>> stream) async {
  final raw = await utf8.decoder.bind(stream).join();
  if (raw.trim().isEmpty) return <String, dynamic>{};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ApiException(400, 'Corpo JSON deve ser um objeto.');
  } on FormatException {
    throw const ApiException(400, 'JSON inválido.');
  }
}

/// Exceção para ficheiro de lições ausente/inválido.
class LessonDataException implements Exception {
  final String message;
  const LessonDataException(this.message);
  @override
  String toString() => message;
}

/// Leitura de lições a partir de assets JSON (fonte única de verdade).
class LessonService {
  final String filePath;
  List<dynamic>? _cache;

  LessonService(this.filePath);

  Future<List<dynamic>> all() async {
    if (_cache != null) return _cache!;
    final file = File(filePath);
    if (!await file.exists()) {
      throw LessonDataException('Ficheiro de lições não encontrado: $filePath');
    }
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic> && decoded['lessons'] is List) {
      _cache = decoded['lessons'] as List<dynamic>;
    } else if (decoded is List) {
      _cache = decoded;
    } else {
      throw LessonDataException('Formato de lições inválido em $filePath');
    }
    return _cache!;
  }

  Future<dynamic> byIndex(int index) async {
    final lessons = await all();
    for (final lesson in lessons) {
      if (lesson is Map<String, dynamic> && lesson['index'] == index) {
        return lesson;
      }
    }
    return null;
  }

  static int totalXp(List<dynamic> lessons) {
    var total = 0;
    for (final lesson in lessons) {
      if (lesson is Map<String, dynamic> && lesson['exercises'] is List) {
        total += (lesson['exercises'] as List).length * 10;
      }
    }
    return max(total, 0);
  }
}