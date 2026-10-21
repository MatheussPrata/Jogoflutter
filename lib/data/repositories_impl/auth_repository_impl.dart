import '../../core/services/auth_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/repositories.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;

  AuthRepositoryImpl(this._authService);

  @override
  Future<User?> getCurrentUser() async {
    return _authService.getSession();
  }

  @override
  Future<User> login(String email, String password) async {
    final user = await _authService.login(email, password);
    if (user == null) {
      throw Exception('Email ou senha inválidos');
    }
    await _authService.saveSession(user);
    return user;
  }

  @override
  Future<User> register(String username, String email, String password) async {
    final user = await _authService.register(username, email, password);
    await _authService.saveSession(user);
    return user;
  }

  @override
  Future<void> logout() async {
    await _authService.logout();
  }

  @override
  Future<void> saveSession(User user) async {
    await _authService.saveSession(user);
  }

  @override
  Future<void> clearSession() async {
    await _authService.clearSession();
  }
}