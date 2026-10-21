import '../../domain/entities/exercise.dart';

class ExerciseResult {
  final bool ok;
  final List<String> output;
  final List<String> messages;

  const ExerciseResult({
    required this.ok,
    required this.output,
    required this.messages,
  });

  factory ExerciseResult.success(List<String> output) {
    return ExerciseResult(ok: true, output: output, messages: []);
  }

  factory ExerciseResult.failure(String message) {
    return ExerciseResult(ok: false, output: [], messages: [message]);
  }
}

ExerciseResult checkExercise(
  Exercise exercise, {
  int? chosenOption,
  List<String>? chosenOrder,
  String? freeText,
}) {
  switch (exercise.kind) {
    case ExerciseKind.gap:
      if (chosenOption == null) {
        return ExerciseResult.failure('Selecione uma opção');
      }
      if (chosenOption == exercise.correctOption) {
        return ExerciseResult.success(['Resposta correta!']);
      }
      return ExerciseResult.failure('Resposta incorreta. Tente novamente.');

    case ExerciseKind.blocks:
      if (chosenOrder == null || chosenOrder.isEmpty) {
        return ExerciseResult.failure('Arraste os blocos para montar o código');
      }
      if (_listEquals(chosenOrder, exercise.correctOrder)) {
        return ExerciseResult.success(['Código montado corretamente!']);
      }
      return ExerciseResult.failure('Ordem incorreta. Verifique a lógica.');

    case ExerciseKind.free:
      if (freeText == null || freeText.trim().isEmpty) {
        return ExerciseResult.failure('Digite seu código');
      }
      // Basic validation - in a real app you'd compile/run the code
      return ExerciseResult.success(['Código enviado: ${freeText.trim()}']);
  }
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}