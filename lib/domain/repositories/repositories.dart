import '../entities/user.dart';
import '../entities/lesson.dart';
import '../entities/transaction.dart';

abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> login(String email, String password);
  Future<User> register(String username, String email, String password);
  Future<void> logout();
  Future<void> saveSession(User user);
  Future<void> clearSession();
}

abstract class LessonRepository {
  Future<List<Lesson>> getAllLessons();
  Future<Lesson?> getLesson(int index);
}

abstract class TransactionRepository {
  Future<List<Transaction>> getAll();
  Future<void> add(Transaction transaction);
  Future<void> remove(String id);
  Future<void> clear();
}
