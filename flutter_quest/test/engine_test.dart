import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quest/engine/parser.dart';
import 'package:flutter_quest/engine/rules.dart';

void main() {
  group('parser', () {
    test('lê um Text simples', () {
      final n = parse("Text('oi')");
      expect(n.name, 'Text');
      expect(n.text, 'oi');
    });

    test('aceita aspas duplas e simples', () {
      expect(parse('Text("oi")').text, 'oi');
      expect(parse("Text('oi')").text, 'oi');
    });

    test('lê widget aninhado', () {
      final n = parse("Center(child: Text('oi'))");
      expect(n.name, 'Center');
      expect(n.children.single.name, 'Text');
      expect(n.children.single.text, 'oi');
    });

    test('lê propriedade numérica', () {
      final n = parse(
        'Container(padding: EdgeInsets.all(12), child: Text("x"))',
      );
      final container = flatten(n).firstWhere((x) => x.name == 'Container');
      expect(container.args['padding']?.texto, 'EdgeInsets.all(12)');
    });

    test('lê children como lista', () {
      final n = parse('''
        Column(children: [
          Text('a'),
          Text('b'),
        ])
      ''');
      expect(n.name, 'Column');
      expect(n.children.length, 2);
      expect(n.children.map((c) => c.text), ['a', 'b']);
    });

    test('ignora comentários', () {
      final n = parse('''
        // comentário
        Text('oi') // outro
      ''');
      expect(n.text, 'oi');
    });

    test('lê Row com dois filhos', () {
      final n = parse('''
        Row(children: [
          Expanded(child: Text('esquerda')),
          Expanded(child: Text('direita')),
        ])
      ''');
      expect(n.children.length, 2);
      expect(n.children.first.name, 'Expanded');
    });

    test('ignora const', () {
      expect(parse("const Text('oi')").text, 'oi');
    });

    test('erro claro quando não é widget', () {
      expect(() => parse('42'), throwsA(isA<ParseError>()));
    });
  });

  group('rules', () {
    test('HasWidget passa quando existe', () {
      final tree = parse("Center(child: Text('oi'))");
      final r = validate(tree, [const HasWidget('Center')]);
      expect(r.ok, isTrue);
    });

    test('HasWidget falha quando não existe', () {
      final tree = parse("Text('oi')");
      final r = validate(tree, [const HasWidget('Center')]);
      expect(r.ok, isFalse);
      expect(r.failures.single, contains('Center'));
    });

    test('HasChild valida hierarquia', () {
      final tree = parse("Center(child: Text('oi'))");
      expect(
        validate(tree, [const HasChild(parent: 'Center', child: 'Text')]).ok,
        isTrue,
      );
      expect(
        validate(tree, [const HasChild(parent: 'Text', child: 'Center')]).ok,
        isFalse,
      );
    });

    test('HasText encontra o texto em qualquer nível', () {
      final tree = parse("Center(child: Container(child: Text('meta')))");
      expect(validate(tree, [const HasText('meta')]).ok, isTrue);
      expect(validate(tree, [const HasText('outro')]).ok, isFalse);
    });

    test('MinChildren conta filhos', () {
      final tree = parse('''
        Column(children: [Text('a'), Text('b')])
      ''');
      expect(validate(tree, [const MinChildren('Column', 2)]).ok, isTrue);
      expect(validate(tree, [const MinChildren('Column', 3)]).ok, isFalse);
    });

    test('IsRoot valida o widget externo', () {
      final tree = parse("Center(child: Text('oi'))");
      expect(validate(tree, [const IsRoot('Center')]).ok, isTrue);
      expect(validate(tree, [const IsRoot('Text')]).ok, isFalse);
    });

    test('HasProperty valida valor', () {
      final tree = parse('Container(borderRadius: 12, child: Text("x"))');
      expect(
        validate(
          tree,
          [const HasProperty('Container', 'borderRadius', equals: '12')],
        ).ok,
        isTrue,
      );
      expect(
        validate(
          tree,
          [const HasProperty('Container', 'borderRadius', equals: '20')],
        ).ok,
        isFalse,
      );
    });

    test('PropertyAtLeast compara números', () {
      final tree = parse('Container(padding: 16, child: Text("x"))');
      expect(
        validate(tree, [const PropertyAtLeast('Container', 'padding', 12)]).ok,
        isTrue,
      );
      expect(
        validate(tree, [const PropertyAtLeast('Container', 'padding', 20)]).ok,
        isFalse,
      );
    });

    test('duas formas de escrever o mesmo código passam igual', () {
      final a = parse("Center(child: Text('oi'))");
      final b = parse('''
        Center(
          child: Text("oi"),
        )
      ''');
      final regras = [
        const IsRoot('Center'),
        const HasChild(parent: 'Center', child: 'Text'),
        const HasText('oi'),
      ];
      expect(validate(a, regras).ok, isTrue);
      expect(validate(b, regras).ok, isTrue);
    });
  });
}
