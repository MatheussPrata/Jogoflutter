import 'exercise.dart';

/// Entidade que representa uma lição do jogo.
class Lesson {
  final int index;
  final String title;
  final String concept;
  final List<Exercise> exercises;

  const Lesson({
    required this.index,
    required this.title,
    required this.concept,
    required this.exercises,
  });

  int get exerciseCount => exercises.length;

  Exercise exerciseAt(int i) => exercises[i];

  Lesson copyWith({
    int? index,
    String? title,
    String? concept,
    List<Exercise>? exercises,
  }) {
    return Lesson(
      index: index ?? this.index,
      title: title ?? this.title,
      concept: concept ?? this.concept,
      exercises: exercises ?? this.exercises,
    );
  }
}