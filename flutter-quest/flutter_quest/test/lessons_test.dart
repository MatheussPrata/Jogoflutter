import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quest/content/exercise.dart';
import 'package:flutter_quest/content/lessons.dart';

void main() {
  group('lacunas', () {
    test('preencher com a opção certa gera código válido', () {
      final ex = licao1.exercises.firstWhere((e) => e.kind == ExerciseKind.gap);
      final code = ex.codeFor(chosenOption: ex.correctOption);
      expect(code.contains('___'), isFalse);
      expect(code.contains('final preco = 8.50;'), isTrue);
    });

    test('código da lacuna roda de verdade', () {
      final ex = licao1.exercises.firstWhere((e) => e.kind == ExerciseKind.gap);
      final r = checkExercise(ex, chosenOption: ex.correctOption);
      expect(r.ok, isTrue, reason: r.messages.join(', '));
      expect(r.output.single, '8.50');
    });

    test('opção errada não preenche corretamente', () {
      final ex = licao1.exercises.firstWhere((e) => e.kind == ExerciseKind.gap);
      final wrong = (ex.correctOption + 1) % ex.options.length;
      final code = ex.codeFor(chosenOption: wrong);
      expect(code, isNot(contains('final preco = 8.50;')));
    });

    test('lacuna do print funciona', () {
      final ex = licao1.exercises.firstWhere(
        (e) => e.kind == ExerciseKind.gap && e.template.contains('___ ('),
      );
      final r = checkExercise(ex, chosenOption: ex.correctOption);
      expect(r.ok, isTrue, reason: r.messages.join(', '));
      expect(r.output.single, '12.00');
    });
  });

  group('blocos', () {
    test('ordem correta monta código que roda', () {
      final ex = licao1.exercises.firstWhere((e) => e.kind == ExerciseKind.blocks);
      final code = ex.codeFor(chosenOrder: ex.correctOrder);
      expect(code, 'final cafe = 8.50 ;');
    });

    test('soma montada com declarações roda e dá 20.5', () {
      final ex = licao1.exercises.firstWhere(
        (e) => e.kind == ExerciseKind.blocks && e.correctOrder.length > 10,
      );
      final code = ex.codeFor(chosenOrder: ex.correctOrder);
      // Agora o exercício inclui as declarações de cafe e pao.
      final r = checkExercise(ex, chosenOrder: ex.correctOrder);
      expect(r.ok, isTrue, reason: r.messages.join(', '));
      expect(r.output, isEmpty); // so print gera saida
      expect(r.variables['total'], 20.5);
    });

    test('blocos incompletos geram código inválido', () {
      final ex = licao1.exercises.firstWhere((e) => e.kind == ExerciseKind.blocks);
      final code = ex.codeFor(chosenOrder: ['a', 'b']);
      final r = checkExercise(ex, chosenOrder: ['a', 'b']);
      expect(r.ok, isFalse);
      expect(code, 'final cafe');
    });
  });

  group('livre', () {
    test('código correto roda', () {
      final ex = licao1.exercises.firstWhere((e) => e.kind == ExerciseKind.free);
      final r = checkExercise(
        ex,
        freeText: 'final leite = 4.75;\nprint(leite);',
      );
      expect(r.ok, isTrue, reason: r.messages.join(', '));
      expect(r.output.single, '4.75');
    });

    test('código vazio não produz saída', () {
      final ex = licao1.exercises.firstWhere((e) => e.kind == ExerciseKind.free);
      final r = checkExercise(ex, freeText: '');
      expect(r.ok, isTrue);
      expect(r.output, isEmpty);
    });
  });

  group('lição completa', () {
    test('tem os três tipos de exercício', () {
      final kinds = licao1.exercises.map((e) => e.kind).toSet();
      expect(kinds, containsAll([
        ExerciseKind.gap,
        ExerciseKind.blocks,
        ExerciseKind.free,
      ]));
    });

    test('expressão tipada is not lost', () {
      // sanity: o avaliador devolve variáveis tipadas
      final r = checkExercise(
        licao1.exercises.firstWhere((e) => e.kind == ExerciseKind.gap),
        chosenOption: 0,
      );
      expect(r.variables['preco'], isNotNull);
    });
  });
}
