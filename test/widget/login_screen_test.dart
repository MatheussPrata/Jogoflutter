import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_quest/core/providers/auth_provider.dart';
import 'package:flutter_quest/domain/entities/user.dart';
import 'package:flutter_quest/domain/repositories/repositories.dart';
import 'package:flutter_quest/presentation/auth/login_screen.dart';

/// Repositório fake em memória para testes de widget.
class _FakeAuthRepository implements AuthRepository {
  User? _session;
  bool shouldFail = false;

  @override
  Future<User?> getCurrentUser() async => _session;

  @override
  Future<User> login(String email, String password) async {
    if (shouldFail) throw Exception('Email ou senha inválidos');
    final user = User(
      id: '1',
      username: 'testuser',
      email: email,
      passwordHash: 'hash',
      salt: 'salt',
      xp: 0,
      createdAt: DateTime(2026, 1, 1),
    );
    _session = user;
    return user;
  }

  @override
  Future<User> register({
    required String username,
    required String email,
    required String password,
    String? inviteCode,
  }) async {
    final user = User(
      id: '2',
      username: username,
      email: email,
      passwordHash: 'hash',
      salt: 'salt',
      xp: 0,
      createdAt: DateTime(2026, 1, 1),
    );
    _session = user;
    return user;
  }

  @override
  Future<void> logout() async {
    _session = null;
  }

  @override
  Future<void> saveSession(User user) async {
    _session = user;
  }

  @override
  Future<void> clearSession() async {
    _session = null;
  }
}

void main() {
  late _FakeAuthRepository repo;

  setUp(() {
    repo = _FakeAuthRepository();
  });

  Widget wrap({Map<String, WidgetBuilder>? routes}) {
    return MaterialApp(
      routes: routes ?? const <String, WidgetBuilder>{},
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Home Screen')),
          );
        }
        return null;
      },
      home: ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(repo),
        child: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen', () {
    testWidgets('renderiza campos e botões', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text('Flutter Quest'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Restaurar sessão salva'), findsOneWidget);
    });

    testWidgets('valida campos vazios', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Digite seu email'), findsOneWidget);
      expect(find.text('Digite sua senha'), findsOneWidget);
    });

    testWidgets('valida email inválido', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'invalido');
      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Email inválido'), findsOneWidget);
    });

    testWidgets('valida senha curta', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Senha deve ter pelo menos 6 caracteres'), findsOneWidget);
    });

    testWidgets('login válido navega para home', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('mostra erro quando login falha', (tester) async {
      repo.shouldFail = true;
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Email ou senha inválidos'), findsOneWidget);
    });

    testWidgets('alterna visibilidade da senha', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      final field = find.byType(TextField).at(1);
      expect(tester.widget<TextField>(field).obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(field).obscureText, isFalse);
    });

    testWidgets('navega para cadastro', (tester) async {
      await tester.pumpWidget(
        wrap(routes: <String, WidgetBuilder>{
          '/register': (_) => const Scaffold(body: Text('Register Screen')),
        }),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cadastre-se'));
      await tester.pumpAndSettle();

      expect(find.text('Register Screen'), findsOneWidget);
    });
  });
}
