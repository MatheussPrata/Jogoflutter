import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_quest/domain/entities/exercise.dart';
import 'package:flutter_quest/domain/entities/lesson.dart';
import 'package:flutter_quest/domain/entities/user.dart';

void main() {
  group('User', () {
    test('copyWith altera apenas os campos informados', () {
      final user = User(
        id: '1',
        username: 'ana',
        email: 'ana@example.com',
        passwordHash: 'hash',
        salt: 'salt',
        xp: 100,
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = user.copyWith(xp: 150);

      expect(updated.xp, 150);
      expect(updated.username, user.username);
      expect(updated.email, user.email);
    });
  });

  group('Exercise', () {
    test('exposes kind helpers', () {
      const gap = Exercise(
        id: 'g',
        kind: ExerciseKind.gap,
        prompt: 'p',
        template: 'var x = ___;',
        options: <String>['1', '2'],
        correctOption: 1,
      );
      const blocks = Exercise(
        id: 'b',
        kind: ExerciseKind.blocks,
        prompt: 'p',
        template: '',
        blocks: <CodeBlock>[
          CodeBlock(id: 'b1', label: 'var'),
          CodeBlock(id: 'b2', label: 'x'),
        ],
        correctOrder: <String>['b1', 'b2'],
      );
      const free = Exercise(
        id: 'f',
        kind: ExerciseKind.free,
        prompt: 'p',
        template: '// code',
      );

      expect(gap.isGap, isTrue);
      expect(gap.isBlocks, isFalse);
      expect(blocks.isBlocks, isTrue);
      expect(free.isFree, isTrue);
      expect(blocks.blocks.length, 2);
      expect(blocks.correctOrder, <String>['b1', 'b2']);
    });
  });

  group('Lesson', () {
    test('exerciseAt e exerciseCount', () {
      const lesson = Lesson(
        index: 0,
        title: 'Variáveis',
        concept: 'conceito',
        exercises: <Exercise>[
          Exercise(
            id: 'e1',
            kind: ExerciseKind.gap,
            prompt: 'p1',
            template: 'a ___ b',
            options: <String>['x'],
            correctOption: 0,
          ),
          Exercise(
            id: 'e2',
            kind: ExerciseKind.free,
            prompt: 'p2',
            template: '// code',
          ),
        ],
      );

      expect(lesson.exerciseCount, 2);
      expect(lesson.exerciseAt(1).id, 'e2');
    });
  });
}
