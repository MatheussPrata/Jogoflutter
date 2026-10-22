import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_quest/core/services/auth_service.dart';
import 'package:flutter_quest/domain/entities/user.dart';

void main() {
  late AuthService authService;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    authService = AuthService(prefs);
  });

  group('AuthService', () {
    test('register cria usuário com senha hasheada e salt', () async {
      final user = await authService.register(
        'testuser',
        'test@example.com',
        'password123',
      );

      expect(user.username, 'testuser');
      expect(user.email, 'test@example.com');
      expect(user.xp, 0);
      expect(user.passwordHash, isNotEmpty);
      expect(user.salt, isNotEmpty);
      expect(user.passwordHash, isNot('password123'));
    });

    test('login funciona com credenciais corretas', () async {
      final created = await authService.register(
        'testuser',
        'test@example.com',
        'password123',
      );

      final logged = await authService.login('test@example.com', 'password123');

      expect(logged, isNotNull);
      expect(logged!.id, created.id);
    });

    test('login retorna null para senha errada', () async {
      await authService.register('testuser', 'test@example.com', 'password123');

      final logged = await authService.login('test@example.com', 'errada');

      expect(logged, isNull);
    });

    test('login retorna null para email inexistente', () async {
      await authService.register('testuser', 'test@example.com', 'password123');

      final logged = await authService.login('outro@example.com', 'password123');

      expect(logged, isNull);
    });

    test('saveSession/getSession persistem a sessão', () async {
      final user = await authService.register(
        'testuser',
        'test@example.com',
        'password123',
      );

      await authService.saveSession(user);
      final session = await authService.getSession();

      expect(session, isNotNull);
      expect(session!.id, user.id);
    });

    test('logout limpa a sessão', () async {
      final user = await authService.register(
        'testuser',
        'test@example.com',
        'password123',
      );
      await authService.saveSession(user);

      await authService.logout();

      expect(await authService.getSession(), isNull);
    });
  });

  group('User serialization', () {
    test('toJson/fromJson preservam dados', () {
      final user = User(
        id: '1',
        username: 'ana',
        email: 'ana@example.com',
        passwordHash: 'hash',
        salt: 'salt',
        xp: 42,
        createdAt: DateTime.parse('2026-01-02T03:04:05.000Z'),
      );

      final restored =
          User.fromJson(jsonDecode(jsonEncode(user.toJson())) as Map<String, dynamic>);

      expect(restored.id, user.id);
      expect(restored.username, user.username);
      expect(restored.email, user.email);
      expect(restored.xp, user.xp);
      expect(restored.createdAt, user.createdAt);
    });
  });
}