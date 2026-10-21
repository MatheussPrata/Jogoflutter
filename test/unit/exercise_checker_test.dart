import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quest/core/utils/exercise_checker.dart';
import 'package:flutter_quest/domain/entities/exercise.dart';

void main() {
  group('Exercise Checker', () {
    group('Gap exercises', () {
      final gapExercise = Exercise(
        id: 'test',
        kind: ExerciseKind.gap,
        prompt: 'Test',
        template: 'var x = ___;',
        options: ['1', '2', '3'],
        correctOption: 1,
        blocks: [],
        correctOrder: [],
      );

      test('returns success for correct option', () {
        final result = checkExercise(gapExercise, chosenOption: 1);
        expect(result.ok, isTrue);
        expect(result.messages, isEmpty);
      });

      test('returns failure for wrong option', () {
        final result = checkExercise(gapExercise, chosenOption: 0);
        expect(result.ok, isFalse);
        expect(result.messages, isNotEmpty);
      });

      test('returns failure for no selection', () {
        final result = checkExercise(gapExercise, chosenOption: null);
        expect(result.ok, isFalse);
      });
    });

    group('Blocks exercises', () {
      final blocksExercise = Exercise(
        id: 'test',
        kind: ExerciseKind.blocks,
        prompt: 'Test',
        template: '',
        options: [],
        correctOption: -1,
        blocks: [
          const CodeBlock(id: 'b1', label: 'var'),
          const CodeBlock(id: 'b2', label: 'x'),
          const CodeBlock(id: 'b3', label: '='),
          const CodeBlock(id: 'b4', label: '1'),
          const CodeBlock(id: 'b5', label: ';'),
        ],
        correctOrder: ['b1', 'b2', 'b3', 'b4', 'b5'],
      );

      test('returns success for correct order', () {
        final result = checkExercise(
          blocksExercise,
          chosenOrder: ['b1', 'b2', 'b3', 'b4', 'b5'],
        );
        expect(result.ok, isTrue);
      });

      test('returns failure for wrong order', () {
        final result = checkExercise(
          blocksExercise,
          chosenOrder: ['b1', 'b3', 'b2', 'b4', 'b5'],
        );
        expect(result.ok, isFalse);
      });

      test('returns failure for incomplete order', () {
        final result = checkExercise(
          blocksExercise,
          chosenOrder: ['b1', 'b2'],
        );
        expect(result.ok, isFalse);
      });

      test('returns failure for empty order', () {
        final result = checkExercise(blocksExercise, chosenOrder: []);
        expect(result.ok, isFalse);
      });

      test('returns failure for null order', () {
        final result = checkExercise(blocksExercise, chosenOrder: null);
        expect(result.ok, isFalse);
      });
    });

    group('Free exercises', () {
      final freeExercise = Exercise(
        id: 'test',
        kind: ExerciseKind.free,
        prompt: 'Test',
        template: '// code here',
        options: [],
        correctOption: -1,
        blocks: [],
        correctOrder: [],
      );

      test('returns success for non-empty code', () {
        final result = checkExercise(freeExercise, freeText: 'var x = 1;');
        expect(result.ok, isTrue);
      });

      test('returns failure for empty code', () {
        final result = checkExercise(freeExercise, freeText: '');
        expect(result.ok, isFalse);
      });

      test('returns failure for whitespace only', () {
        final result = checkExercise(freeExercise, freeText: '   ');
        expect(result.ok, isFalse);
      });

      test('returns failure for null code', () {
        final result = checkExercise(freeExercise, freeText: null);
        expect(result.ok, isFalse);
      });
    });
  });
}