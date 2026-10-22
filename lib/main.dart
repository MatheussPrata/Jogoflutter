import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/providers/auth_provider.dart';
import 'core/providers/lesson_provider.dart';
import 'core/providers/transaction_provider.dart';
import 'core/services/auth_service.dart';
import 'data/repositories_impl/auth_repository_impl.dart';
import 'data/repositories_impl/lesson_repository_impl.dart';
import 'data/repositories_impl/transaction_repository_impl.dart';
import 'domain/repositories/repositories.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/home/home_screen.dart';
import 'presentation/lesson/lesson_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final AuthRepository authRepository = AuthRepositoryImpl(AuthService(prefs));
  final LessonRepository lessonRepository = LessonRepositoryImpl();
  final TransactionRepository transactionRepository =
      TransactionRepositoryImpl(prefs);

  runApp(
    FlutterQuestApp(
      authRepository: authRepository,
      lessonRepository: lessonRepository,
      transactionRepository: transactionRepository,
    ),
  );
}

class FlutterQuestApp extends StatelessWidget {
  final AuthRepository authRepository;
  final LessonRepository lessonRepository;
  final TransactionRepository transactionRepository;

  const FlutterQuestApp({
    super.key,
    required this.authRepository,
    required this.lessonRepository,
    required this.transactionRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authRepository)..initialize(),
        ),
        ChangeNotifierProvider<LessonProvider>(
          create: (_) => LessonProvider(lessonRepository)..loadLessons(),
        ),
        ChangeNotifierProvider<TransactionProvider>(
          create: (_) => TransactionProvider(transactionRepository)..load(),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Quest',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        routes: <String, WidgetBuilder>{
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home': (_) => const HomeScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/lesson') {
            final index = settings.arguments is int
                ? settings.arguments! as int
                : 0;
            return MaterialPageRoute<void>(
              builder: (_) => LessonScreen(lessonIndex: index),
            );
          }
          return null;
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (authProvider.isLoggedIn) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}