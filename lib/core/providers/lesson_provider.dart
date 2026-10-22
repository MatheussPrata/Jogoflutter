import 'package:flutter/material.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/repositories/repositories.dart';

class LessonProvider extends ChangeNotifier {
  final LessonRepository _lessonRepository;
  List<Lesson> _lessons = [];
  bool _isLoading = false;
  String? _error;

  LessonProvider(this._lessonRepository);

  List<Lesson> get lessons => _lessons;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLessons() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _lessons = await _lessonRepository.getAllLessons();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Lesson? getLesson(int index) {
    if (index >= 0 && index < _lessons.length) {
      return _lessons[index];
    }
    return null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}