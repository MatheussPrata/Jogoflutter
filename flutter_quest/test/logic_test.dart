import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quest/engine/logic.dart';

void main() {
  group('Etapa 1 - lógica', () {
    test('declara variável e soma', () {
      final r = runLogic('''
        final a = 10;
        final b = 5;
        print(a + b);
      ''');
      expect(r.ok, isTrue, reason: r.error);
      expect(r.output.single, '15');
    });

    test('multiplicação com decimal', () {
      final r = runLogic('''
        final preco = 29.90;
        final desconto = preco * 0.1;
        print(preco - desconto);
      ''');
      expect(r.ok, isTrue, reason: r.error);
      expect(r.output.single, '26.91');
    });

    test('concatenação de texto', () {
      final r = runLogic("""
        final nome = 'Matheus';
        print('Oi, ' + nome);
      """);
      expect(r.output.single, 'Oi, Matheus');
    });

    test('variável de texto com número', () {
      final r = runLogic("""
        final item = 'Café';
        final qtd = 2;
        print(item + ': ' + qtd.toString());
      """);
      // toString() não é suportado ainda — deve falhar de forma clara.
      expect(r.ok, isFalse);
    });

    test('divisão', () {
      final r = runLogic('print(10 / 4);');
      expect(r.output.single, '2.50');
    });

    test('número inteiro não vira 10.0', () {
      final r = runLogic('print(10);');
      expect(r.output.single, '10');
    });

    test('variável inexistente dá erro claro', () {
      final r = runLogic('print(total);');
      expect(r.ok, isFalse);
      expect(r.error, contains('total'));
      expect(r.error, contains('não existe'));
    });

    test('erro de sintaxe é reportado', () {
      final r = runLogic('final = 10;');
      expect(r.ok, isFalse);
      expect(r.error, isNotNull);
    });

    test('lista as variáveis no fim', () {
      final r = runLogic('''
        final preco = 10;
        final qtd = 3;
      ''');
      expect(r.variables.length, 2);
      expect(r.variables.first.name, 'preco');
    });

    test('múltiplos prints', () {
      final r = runLogic('''
        print(1);
        print(2);
      ''');
      expect(r.output, ['1', '2']);
    });
  });
}
