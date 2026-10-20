// Conteúdo do jogo: lições compostas de exercícios.
//
// Separado do código de propósito — adicionar lição não deve exigir tocar
// em widget nenhum. Cada lição é um superconjunto da anterior.

import '../engine/logic.dart';
import 'exercise.dart';

/// Uma lição: um conceito só, com 4-6 exercícios.
class Lesson {
  final int id;
  final String title;
  final String concept;
  final List<Exercise> exercises;

  const Lesson({
    required this.id,
    required this.title,
    required this.concept,
    required this.exercises,
  });
}

/// Resultado de um exercício.
class ExerciseResult {
  final bool ok;
  final List<String> messages;
  final List<String> output;
  final Map<String, Object?> variables;

  const ExerciseResult({
    required this.ok,
    this.messages = const [],
    this.output = const [],
    this.variables = const {},
  });
}

/// Roda o exercício e confere a saída e as variáveis.
ExerciseResult checkExercise(
  Exercise exercise, {
  int? chosenOption,
  List<String>? chosenOrder,
  String? freeText,
}) {
  final code = exercise.codeFor(
    chosenOption: chosenOption,
    chosenOrder: chosenOrder,
    freeText: freeText,
  );

  final run = runLogic(code);
  if (!run.ok) {
    return ExerciseResult(ok: false, messages: [run.error ?? 'Erro desconhecido.']);
  }

  return ExerciseResult(
    ok: true,
    output: run.output,
    variables: {for (final v in run.variables) v.name: v.value},
  );
}

/// Compara a saída do aluno com a esperada (usado para dar o "certo/errado").
bool outputMatches(ExerciseResult result, List<String> expected) {
  if (!result.ok) return false;
  if (result.output.length != expected.length) return false;
  for (var i = 0; i < expected.length; i++) {
    if (result.output[i].trim() != expected[i].trim()) return false;
  }
  return true;
}

// ---------------------------------------------------------------------------
// Lição 1 — variáveis e números
// ---------------------------------------------------------------------------

const licao1 = Lesson(
  id: 1,
  title: 'Variáveis',
  concept:
      '`final` guarda um valor com nome. `print()` mostra na tela. '
      'Número decimal usa ponto, não vírgula.',
  exercises: [
    Exercise.gap(
      id: 1,
      prompt: 'Complete para criar a variável preco valendo 8.50:',
      template: 'final preco ___ 8.50;\nprint(preco);',
      options: ['=', '==', ':'],
      correctOption: 0,
      explanation:
          '`=` guarda o valor na variável. `==` compara, `:` é usado em '
          'outros lugares — não para atribuir.',
    ),
    Exercise.blocks(
      id: 2,
      prompt: 'Monte a linha que cria a variável café com o valor 8.50:',
      blocks: [
        CodeBlock('a', 'final'),
        CodeBlock('b', 'cafe'),
        CodeBlock('c', '='),
        CodeBlock('d', '8.50'),
        CodeBlock('e', ';'),
        CodeBlock('x1', 'var'),
        CodeBlock('x2', '=='),
        CodeBlock('x3', '8,50'),
      ],
      correctOrder: ['a', 'b', 'c', 'd', 'e'],
      explanation:
          'A ordem é sempre: tipo da variável, nome, sinal de igual, '
          'valor e ponto-e-vírgula no final.',
    ),
    Exercise.gap(
      id: 3,
      prompt: 'Complete para mostrar o valor na tela:',
      template: "final pao = 12.00;\n___ (pao);",
      options: ['print', 'show', 'text'],
      correctOption: 0,
      explanation: '`print()` é a função que escreve na saída.',
    ),
    Exercise.blocks(
      id: 4,
      prompt:
          'Monte o código completo: declare café, pão e some em total:',
      blocks: [
        CodeBlock('a', 'final'),
        CodeBlock('b', 'cafe'),
        CodeBlock('c', '='),
        CodeBlock('d', '8.50'),
        CodeBlock('e', ';'),
        CodeBlock('f', 'final'),
        CodeBlock('g', 'pao'),
        CodeBlock('h', '='),
        CodeBlock('i', '12.00'),
        CodeBlock('j', ';'),
        CodeBlock('k', 'final'),
        CodeBlock('l', 'total'),
        CodeBlock('m', '='),
        CodeBlock('n', 'cafe'),
        CodeBlock('o', '+'),
        CodeBlock('p', 'pao'),
        CodeBlock('q', ';'),
        CodeBlock('x1', '*'),
        CodeBlock('x2', '-'),
        CodeBlock('x3', 'total'),
      ],
      correctOrder: [
        'a', 'b', 'c', 'd', 'e',
        'f', 'g', 'h', 'i', 'j',
        'k', 'l', 'm', 'n', 'o', 'p', 'q',
      ],
      explanation:
          'Primeiro declara as variáveis, depois usa elas na conta. '
          'A ordem das declarações não importa, mas todas precisam vir antes '
          'de usar as variáveis.',
    ),
    Exercise.free(
      id: 5,
      prompt:
          'Agora sozinho: crie a variável leite valendo 4.75 e mostre '
          'na tela.',
      template: 'void main() {\n  \n}',
      explanation:
          'Duas linhas: uma cria a variável, outra mostra o valor.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Lição 2 — if/else e comparações
// ---------------------------------------------------------------------------

const licao2 = Lesson(
  id: 2,
  title: 'Decisões',
  concept:
      '`if` executa um bloco só quando a condição é verdadeira. '
      'Operadores: `>`, `<`, `>=`, `<=`, `==`, `!=`. '
      '`else` pega o caso contrário.',
  exercises: [
    Exercise.gap(
      id: 1,
      prompt: 'Complete a condição: mostre "caro" se preco > 20:',
      template:
          'final preco = 25.00;\nif (preco > 20) {\n  print("caro");\n}',
      options: ['print("caro")', 'print("barato")'],
      correctOption: 0,
      explanation:
          'Quando a condição é verdadeira, o código dentro do `if` roda.',
    ),
    Exercise.gap(
      id: 2,
      prompt: 'Complete o else para mostrar "barato" quando não for caro:',
      template:
          'final preco = 15.00;\nif (preco > 20) {\n  print("caro");\n} ___ {\n  print("barato");\n}',
      options: ['else', 'then', 'elseif'],
      correctOption: 0,
      explanation: '`else` executa quando a condição do `if` é falsa.',
    ),
    Exercise.blocks(
      id: 3,
      prompt:
          'Monte a verificação completa: se preco >= 50 -> "premium", senão -> "basico":',
      blocks: [
        CodeBlock('a', 'final'),
        CodeBlock('b', 'preco'),
        CodeBlock('c', '='),
        CodeBlock('d', '35.00'),
        CodeBlock('e', ';'),
        CodeBlock('f', 'if'),
        CodeBlock('g', '('),
        CodeBlock('h', 'preco'),
        CodeBlock('i', '>='),
        CodeBlock('j', '50'),
        CodeBlock('k', ')'),
        CodeBlock('l', '{'),
        CodeBlock('m', 'print'),
        CodeBlock('n', '('),
        CodeBlock('o', '"premium"'),
        CodeBlock('p', ')'),
        CodeBlock('q', ';'),
        CodeBlock('r', '}'),
        CodeBlock('s', 'else'),
        CodeBlock('t', '{'),
        CodeBlock('u', 'print'),
        CodeBlock('v', '('),
        CodeBlock('w', '"basico"'),
        CodeBlock('x', ')'),
        CodeBlock('y', ';'),
        CodeBlock('z', '}'),
        CodeBlock('x1', '<='),
        CodeBlock('x2', '=='),
        CodeBlock('x3', 'then'),
      ],
      correctOrder: [
        'a', 'b', 'c', 'd', 'e',
        'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r',
        's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
      ],
      explanation:
          'Estrutura completa: `if (condicao) { ... } else { ... }`. '
          'O `else` não tem condição — pega tudo que não entrou no `if`.',
    ),
    Exercise.gap(
      id: 4,
      prompt: 'Qual operador testa se duas coisas são iguais?',
      template:
          'final a = 10;\nfinal b = 10;\nif (a ___ b) {\n  print("iguais");\n}',
      options: ['=', '==', '!=', '>='],
      correctOption: 1,
      explanation:
          '`=` atribui. `==` compara igualdade. `!=` testa diferença.',
    ),
    Exercise.free(
      id: 5,
      prompt:
          'Livre: crie uma variável idade = 17. Se idade >= 18, mostre "maior", senão "menor".',
      template: 'void main() {\n  \n}',
      explanation:
          'Use `if (idade >= 18) { print("maior"); } else { print("menor"); }`.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Lição 3 — Ponte: lógica → primeiro widget Text
// ---------------------------------------------------------------------------

const licao3 = Lesson(
  id: 3,
  title: 'Primeiro widget',
  concept:
      'Agora seu cálculo vira algo na tela. O widget `Text` mostra texto. '
      'Você já sabe calcular — agora só envolve no `Text()`.',
  exercises: [
    Exercise.gap(
      id: 1,
      prompt: 'Complete para mostrar o total na tela com Text:',
      template:
          'final total = 20.50;\n___ ( "Total: R\$ " + total.toStringAsFixed(2) );',
      options: ['Text', 'print', 'show'],
      correctOption: 0,
      explanation:
          '`Text("...")` cria um widget que desenha o texto na tela. '
          'Diferente do `print()`, que só aparece no console.',
    ),
    Exercise.blocks(
      id: 2,
      prompt:
          'Monte o widget que mostra o preço com "R\$" e duas casas:',
      blocks: [
        CodeBlock('a', 'Text'),
        CodeBlock('b', '('),
        CodeBlock('c', '"R\$ "'),
        CodeBlock('d', '+'),
        CodeBlock('e', 'preco'),
        CodeBlock('f', '.'),
        CodeBlock('g', 'toStringAsFixed'),
        CodeBlock('h', '('),
        CodeBlock('i', '2'),
        CodeBlock('j', ')'),
        CodeBlock('k', ')'),
        CodeBlock('x1', 'print'),
        CodeBlock('x2', 'show'),
        CodeBlock('x3', 'NumberFormat'),
      ],
      correctOrder: ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k'],
      explanation:
          '`toStringAsFixed(2)` garante duas casas decimais — essencial '
          'para dinheiro. O `+` junta o R\$ " com o número formatado.',
    ),
    Exercise.gap(
      id: 3,
      prompt: 'Complete para mostrar "Parabéns!" centralizado:',
      template:
          'Center(\n  child: ___ ( "Parabéns!" ),\n)',
      options: ['Text', 'Container', 'Column'],
      correctOption: 0,
      explanation:
          '`Center` centraliza o filho. `Text` é o que desenha o texto.',
    ),
    Exercise.blocks(
      id: 4,
      prompt:
          'Monte o código completo: calcule 10% de desconto em 100.00 e mostre no Text:',
      blocks: [
        CodeBlock('a', 'final'),
        CodeBlock('b', 'preco'),
        CodeBlock('c', '='),
        CodeBlock('d', '100.00'),
        CodeBlock('e', ';'),
        CodeBlock('f', 'final'),
        CodeBlock('g', 'desconto'),
        CodeBlock('h', '='),
        CodeBlock('i', 'preco'),
        CodeBlock('j', '*'),
        CodeBlock('k', '0.1'),
        CodeBlock('l', ';'),
        CodeBlock('m', 'final'),
        CodeBlock('n', 'final'),
        CodeBlock('o', '='),
        CodeBlock('p', 'preco'),
        CodeBlock('q', '-'),
        CodeBlock('r', 'desconto'),
        CodeBlock('s', ';'),
        CodeBlock('t', 'Text'),
        CodeBlock('u', '('),
        CodeBlock('v', '"Com desconto: R\$ "'),
        CodeBlock('w', '+'),
        CodeBlock('x', 'final'),
        CodeBlock('y', '.'),
        CodeBlock('z', 'toStringAsFixed'),
        CodeBlock('a1', '('),
        CodeBlock('b1', '2'),
        CodeBlock('c1', ')'),
        CodeBlock('d1', ')'),
        CodeBlock('x1', 'print'),
        CodeBlock('x2', 'Center'),
      ],
      correctOrder: [
        'a', 'b', 'c', 'd', 'e',
        'f', 'g', 'h', 'i', 'j', 'k', 'l',
        'm', 'n', 'o', 'p', 'q', 'r', 's',
        't', 'u', 'v', 'w', 'x', 'y', 'z', 'a1', 'b1', 'c1', 'd1',
      ],
      explanation:
          'Cálculo + widget junto: a lógica que você já sabe alimenta '
          'o `Text`. O `Center` envolve para centralizar na tela.',
    ),
    Exercise.free(
      id: 5,
      prompt:
          'Livre: calcule a soma de 15.50 + 24.90 e mostre no Text centralizado.',
      template: 'void main() {\n  \n}',
      explanation:
          'Use `Center(child: Text("Total: R\$ " + (15.50 + 24.90).toStringAsFixed(2)))`.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Lição 4 — Container, cor, padding, borda
// ---------------------------------------------------------------------------

const licao4 = Lesson(
  id: 4,
  title: 'Caixas bonitas',
  concept:
      '`Container` é a caixa que agrupa tudo: cor, borda, padding, '
      'margem, sombra. `Text` vai dentro.',
  exercises: [
    Exercise.gap(
      id: 1,
      prompt: 'Complete para dar cor de fundo ao Container:',
      template:
          'Container(\n  color: ___,\n  child: Text("Olá"),\n)',
      options: ['Colors.blue', 'Color.blue', 'blue'],
      correctOption: 0,
      explanation:
          'Cores vêm de `Colors.nome`. `Colors.blue`, `Colors.red`, '
          '`Colors.green`, `Colors.amber`, etc.',
    ),
    Exercise.gap(
      id: 2,
      prompt: 'Complete para adicionar padding interno de 16:',
      template:
          'Container(\n  padding: EdgeInsets.___ (16),\n  color: Colors.blue,\n  child: Text("Com espaço"),\n)',
      options: ['all', 'only', 'symmetric'],
      correctOption: 0,
      explanation:
          '`EdgeInsets.all(16)` coloca 16 em todos os lados. '
          '`symmetric(horizontal: 16, vertical: 8)` faz lados opostos iguais.',
    ),
    Exercise.blocks(
      id: 3,
      prompt:
          'Monte um Container vermelho com borda arredondada e texto branco:',
      blocks: [
        CodeBlock('a', 'Container'),
        CodeBlock('b', '('),
        CodeBlock('c', 'decoration'),
        CodeBlock('d', ':'),
        CodeBlock('e', 'BoxDecoration'),
        CodeBlock('f', '('),
        CodeBlock('g', 'color'),
        CodeBlock('h', ':'),
        CodeBlock('i', 'Colors.red'),
        CodeBlock('j', ','),
        CodeBlock('k', 'borderRadius'),
        CodeBlock('l', ':'),
        CodeBlock('m', 'BorderRadius.circular'),
        CodeBlock('n', '('),
        CodeBlock('o', '12'),
        CodeBlock('p', ')'),
        CodeBlock('q', ')'),
        CodeBlock('r', ','),
        CodeBlock('s', 'child'),
        CodeBlock('t', ':'),
        CodeBlock('u', 'Text'),
        CodeBlock('v', '('),
        CodeBlock('w', '"Olá Container"'),
        CodeBlock('x', ')'),
        CodeBlock('y', ')'),
        CodeBlock('x1', 'padding'),
        CodeBlock('x2', 'margin'),
        CodeBlock('x3', 'Colors.blue'),
      ],
      correctOrder: [
        'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l',
        'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y',
      ],
      explanation:
          '`BoxDecoration` agrupa cor, borda, sombra, raio. '
          '`BorderRadius.circular(12)` arredonda os cantos.',
    ),
    Exercise.gap(
      id: 4,
      prompt: 'Complete para sombra suave:',
      template:
          'Container(\n  decoration: BoxDecoration(\n    color: Colors.white,\n    boxShadow: [\n      BoxShadow(\n        color: Colors.black26,\n        blurRadius: ___,\n        offset: Offset(0, 2),\n      ),\n    ],\n  ),\n  child: Text("Com sombra"),\n)',
      options: ['4', '0', '20'],
      correctOption: 0,
      explanation:
          '`blurRadius` controla o desfoque. 4 é sutil, 20 é forte. '
          '`offset` desloca a sombra (x, y).',
    ),
    Exercise.free(
      id: 5,
      prompt:
          'Livre: Container azul claro, padding 16, borda arredondada 8, texto "Estilo" branco.',
      template: 'void main() {\n  \n}',
      explanation:
          'Use `BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(8))` '
          'e `Text("Estilo", style: TextStyle(color: Colors.white))`.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Lição 5 — Row, Column, Expanded
// ---------------------------------------------------------------------------

const licao5 = Lesson(
  id: 5,
  title: 'Layout',
  concept:
      '`Row` = horizontal, `Column` = vertical. `Expanded` divide o espaço '
      'como `weight()` no Compose. Sem `Expanded`, filho manda no tamanho.',
  exercises: [
    Exercise.gap(
      id: 1,
      prompt: 'Complete para colocar dois textos lado a lado:',
      template:
          '___ (\n  children: [\n    Text("Esquerda"),\n    Text("Direita"),\n  ],\n)',
      options: ['Row', 'Column', 'Stack'],
      correctOption: 0,
      explanation: '`Row` = linha (horizontal). `Column` = coluna (vertical).',
    ),
    Exercise.gap(
      id: 2,
      prompt: 'Complete para o filho da direita ocupar o espaço que sobra:',
      template:
          'Row(\n  children: [\n    Text("Fixo"),\n    ___ (\n      child: Text("Elástico"),\n    ),\n  ],\n)',
      options: ['Expanded', 'Flexible', 'SizedBox'],
      correctOption: 0,
      explanation:
          '`Expanded` = "ocupe todo o espaço que sobrar". '
          'Sem ele, o filho usa só o tamanho do conteúdo.',
    ),
    Exercise.blocks(
      id: 3,
      prompt:
          'Monte: três caixas coloridas, a do meio ocupa 2x o espaço das outras:',
      blocks: [
        CodeBlock('a', 'Row'),
        CodeBlock('b', '('),
        CodeBlock('c', 'children'),
        CodeBlock('d', ':'),
        CodeBlock('e', '['),
        CodeBlock('f', 'Expanded'),
        CodeBlock('g', '('),
        CodeBlock('h', 'child'),
        CodeBlock('i', ':'),
        CodeBlock('j', 'Container'),
        CodeBlock('k', '('),
        CodeBlock('l', 'color'),
        CodeBlock('m', ':'),
        CodeBlock('n', 'Colors.red'),
        CodeBlock('o', ')'),
        CodeBlock('p', ')'),
        CodeBlock('q', ','),
        CodeBlock('r', 'Expanded'),
        CodeBlock('s', '('),
        CodeBlock('t', 'flex'),
        CodeBlock('u', ':'),
        CodeBlock('v', '2'),
        CodeBlock('w', 'child'),
        CodeBlock('x', ':'),
        CodeBlock('y', 'Container'),
        CodeBlock('z', '('),
        CodeBlock('a1', 'color'),
        CodeBlock('b1', ':'),
        CodeBlock('c1', 'Colors.green'),
        CodeBlock('d1', ')'),
        CodeBlock('e1', ')'),
        CodeBlock('f1', ','),
        CodeBlock('g1', 'Expanded'),
        CodeBlock('h1', '('),
        CodeBlock('i1', 'child'),
        CodeBlock('j1', ':'),
        CodeBlock('k1', 'Container'),
        CodeBlock('l1', '('),
        CodeBlock('m1', 'color'),
        CodeBlock('n1', ':'),
        CodeBlock('o1', 'Colors.blue'),
        CodeBlock('p1', ')'),
        CodeBlock('q1', ')'),
        CodeBlock('r1', ')'),
        CodeBlock('s1', ']'),
        CodeBlock('t1', ')'),
        CodeBlock('x1', 'flex: 1'),
        CodeBlock('x2', 'Column'),
      ],
      correctOrder: [
        'a', 'b', 'c', 'd', 'e',
        'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q',
        'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'a1', 'b1', 'c1', 'd1', 'e1', 'f1', 'g1', 'h1', 'i1', 'j1', 'k1', 'l1', 'm1', 'n1', 'o1', 'p1', 'q1', 'r1', 's1', 't1',
      ],
      explanation:
          '`flex` define a proporção. 1 : 2 : 1 = a do meio recebe o dobro '
          'do espaço das outras. Total = 4 partes; a do meio = 2/4 = 50%.',
    ),
    Exercise.gap(
      id: 4,
      prompt: 'Complete para empilhar verticalmente com espaçamento:',
      template:
          'Column(\n  mainAxisAlignment: MainAxisAlignment.___,\n  children: [\n    Text("Topo"),\n    Text("Meio"),\n    Text("Base"),\n  ],\n)',
      options: ['spaceEvenly', 'center', 'start'],
      correctOption: 0,
      explanation:
          '`spaceEvenly` = espaço igual antes, entre e depois. '
          '`center` centraliza o grupo. `start` encosta no topo.',
    ),
    Exercise.free(
      id: 5,
      prompt:
          'Livre: Row com 3 containers — esquerda fixa 60px, meio expande, direita fixa 60px. Cores diferentes.',
      template: 'void main() {\n  \n}',
      explanation:
          'Use `SizedBox(width: 60)` pros fixos, `Expanded(child: Container(...))` pro meio.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Lição 6 — Estado (StatefulWidget, setState)
// ---------------------------------------------------------------------------

const licao6 = Lesson(
  id: 6,
  title: 'Estado',
  concept:
      'Até agora tudo era estático (`StatelessWidget`). Para mudar a tela '
      'após o app rodar, precisa de `StatefulWidget` + `setState()`. '
      'O `setState()` avisa o Flutter: "reconstrua, mudou algo".',
  exercises: [
    Exercise.gap(
      id: 1,
      prompt: 'Complete o widget com estado mutável:',
      template:
          'class Contador extends ___ {\n  @override\n  State<Contador> createState() => _ContadorState();\n}',
      options: ['StatefulWidget', 'StatelessWidget', 'Widget'],
      correctOption: 0,
      explanation:
          '`StatefulWidget` = tem estado que muda. '
          '`StatelessWidget` = nunca muda depois de criado.',
    ),
    Exercise.gap(
      id: 2,
      prompt: 'Complete o método que muda o estado:',
      template:
          'void _incrementar() {\n  ___ (() {\n    contador++;\n  });\n}',
      options: ['setState', 'setstate', 'updateState'],
      correctOption: 0,
      explanation:
          '`setState(() { ... })` marca a variável como suja e agenda '
          'a reconstrução do widget. Fora dele, a tela não atualiza.',
    ),
    Exercise.blocks(
      id: 3,
      prompt:
          'Monte o contador completo: variável, método, botão que incrementa:',
      blocks: [
        CodeBlock('a', 'class'),
        CodeBlock('b', 'Contador'),
        CodeBlock('c', 'extends'),
        CodeBlock('d', 'StatefulWidget'),
        CodeBlock('e', '{'),
        CodeBlock('f', '@override'),
        CodeBlock('g', 'State<Contador>'),
        CodeBlock('h', 'createState()'),
        CodeBlock('i', '=>'),
        CodeBlock('j', '_ContadorState();'),
        CodeBlock('k', '}'),
        CodeBlock('l', 'class'),
        CodeBlock('m', '_ContadorState'),
        CodeBlock('n', 'extends'),
        CodeBlock('o', 'State<Contador>'),
        CodeBlock('p', '{'),
        CodeBlock('q', 'int'),
        CodeBlock('r', 'contador'),
        CodeBlock('s', '='),
        CodeBlock('t', '0;'),
        CodeBlock('u', 'void'),
        CodeBlock('v', '_incrementar()'),
        CodeBlock('w', '{'),
        CodeBlock('x', 'setState'),
        CodeBlock('y', '('),
        CodeBlock('z', '()'),
        CodeBlock('a1', '{'),
        CodeBlock('b1', 'contador'),
        CodeBlock('c1', '++;'),
        CodeBlock('d1', '}'),
        CodeBlock('e1', '}'),
        CodeBlock('f1', '@override'),
        CodeBlock('g1', 'Widget'),
        CodeBlock('h1', 'build'),
        CodeBlock('i1', '(BuildContext'),
        CodeBlock('j1', 'context)'),
        CodeBlock('k1', '{'),
        CodeBlock('l1', 'return'),
        CodeBlock('m1', 'Column'),
        CodeBlock('n1', '('),
        CodeBlock('o1', 'children'),
        CodeBlock('p1', ':'),
        CodeBlock('q1', '['),
        CodeBlock('r1', 'Text'),
        CodeBlock('s1', '('),
        CodeBlock('t1', '"Contador: \\\$contador"'),
        CodeBlock('u1', ')'),
        CodeBlock('v1', ','),
        CodeBlock('w1', 'ElevatedButton'),
        CodeBlock('x1', '('),
        CodeBlock('y1', 'onPressed'),
        CodeBlock('z1', ':'),
        CodeBlock('a2', '_incrementar'),
        CodeBlock('b2', ','),
        CodeBlock('c2', 'child'),
        CodeBlock('d2', ':'),
        CodeBlock('e2', 'Text'),
        CodeBlock('f2', '('),
        CodeBlock('g2', '"Incrementar"'),
        CodeBlock('h2', ')'),
        CodeBlock('i2', ')'),
        CodeBlock('j2', ')'),
        CodeBlock('k2', ')'),
        CodeBlock('l2', ']'),
        CodeBlock('m2', ')'),
        CodeBlock('n2', ';'),
        CodeBlock('o2', '}'),
        CodeBlock('p2', '}'),
        CodeBlock('x1', 'StatelessWidget'),
        CodeBlock('x2', 'print'),
      ],
      correctOrder: [
        'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k',
        'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
        'w', 'x', 'y', 'z', 'a1', 'b1', 'c1', 'd1', 'e1', 'f1',
        'g1', 'h1', 'i1', 'j1', 'k1', 'l1', 'm1', 'n1', 'o1',
        'p1', 'q1', 'r1', 's1', 't1', 'u1', 'v1', 'w1', 'x1',
        'y1', 'z1', 'a2', 'b2', 'c2', 'd2', 'e2', 'f2', 'g2',
        'h2', 'i2', 'j2', 'k2', 'l2', 'm2', 'n2', 'o2',
      ],
      explanation:
          'Estrutura padrão: `StatefulWidget` + classe `State` privada. '
          'Variável na classe `State`, `setState` no método, `build` lê a variável.',
    ),
    Exercise.gap(
      id: 4,
      prompt: 'O que NÃO dispara reconstrução se mudar direto (sem setState)?',
      template:
          'void errado() {\n  contador = 10; // ___\n}',
      options: ['não atualiza a tela', 'atualiza a tela', 'dá erro'],
      correctOption: 0,
      explanation:
          'Mudar a variável sem `setState` não avisa o Flutter. '
          'A tela fica velha até algo disparar rebuild.',
    ),
    Exercise.free(
      id: 5,
      prompt:
          'Livre: contador que decrementa também. Botão "-" diminui, "+" aumenta.',
      template: 'void main() {\n  \n}',
      explanation:
          'Dois métodos: `_incrementar()` e `_decrementar()`, cada um com '
          'seu `setState`. Dois botões na coluna.',
    ),
  ],
);

// All lessons
const allLessons = <Lesson>[
  licao1,
  licao2,
  licao3,
  licao4,
  licao5,
  licao6,
];