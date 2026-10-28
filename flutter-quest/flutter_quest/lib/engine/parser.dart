// Parser do subconjunto de Dart usado pelo Flutter Quest.
//
// O aluno escreve coisa assim:
//   Center(child: Container(padding: EdgeInsets.all(8), child: Text('oi')))
//
// E o parser devolve:
//   Node('Center', {}, [Node('Container', {'padding': EdgeInsets.all(8)}, [Node('Text', {'data': 'oi'}, [])])])
//
// Nada de compilador: é um lexer + parser recursivo para chamadas de
// construtor de widget. Suficiente para o jogo e rápido o bastante para
// validar a cada tecla.

import 'lexer.dart';

export 'lexer.dart' show TokType, Token, ParseError, tokenize;

/// Um valor literal (string, número, booleano, null) ou expressão simples.
sealed class Value {
  const Value();

  /// Representação textual estável, usada nas regras de validação.
  String get texto;
}

class StringValue extends Value {
  final String value;
  const StringValue(this.value);
  @override
  String get texto => value;
}

class NumberValue extends Value {
  final double value;
  const NumberValue(this.value);
  @override
  String get texto => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

class BoolValue extends Value {
  final bool value;
  const BoolValue(this.value);
  @override
  String get texto => value.toString();
}

class NullValue extends Value {
  const NullValue();
  @override
  String get texto => 'null';
}

/// Valor que o parser não soube interpretar (ex.: `Colors.blue[500]`).
class RawValue extends Value {
  final String value;
  const RawValue(this.value);
  @override
  String get texto => value;
}

/// Um widget (ou chamada) construído no código.
class Node {
  final String name;
  final Map<String, Value> args;

  /// Argumentos posicionais, sem nome (o primeiro de `Text('oi')`).
  final List<Value> positional;
  final List<Node> children;

  const Node(this.name, this.args, this.children, {this.positional = const []});

  /// Texto principal: `Text('oi')` -> "oi".
  String? get text {
    final direct = args['data']?.texto;
    if (direct != null) return direct;
    return positional.isNotEmpty ? positional.first.texto : null;
  }

  @override
  String toString() => _describe(this, 0);

  String _describe(Node n, int depth) {
    final pad = '  ' * depth;
    final argText = n.args.isEmpty
        ? ''
        : n.args.entries.map((e) => '${e.key}: ${e.value.texto}').join(', ');
    final buf = StringBuffer('$pad${n.name}($argText)');
    for (final c in n.children) {
      buf.write('\n${_describe(c, depth + 1)}');
    }
    return buf.toString();
  }
}

/// Faz o parse do código e devolve a raiz.
///
/// O código pode ser uma expressão solta ou uma função `build` completa;
/// nesse caso a última expressão de widget do corpo é usada.
Node parse(String source) {
  final parser = _Parser(tokenize(source));
  final root = parser.parseWidgetExpression();
  return root;
}

/// Parse tolerante: devolve a lista de widgets encontrados (todos os nós
/// de topo) — útil para mensagens de erro mais gentis.
List<Node> parseAll(String source) {
  final parser = _Parser(tokenize(source));
  final nodes = <Node>[];
  parser.skipIgnorable();
  while (!parser.isDone) {
    final before = parser.pos;
    try {
      nodes.add(parser.parseWidgetExpression());
    } catch (_) {
      parser.pos = before + 1;
    }
    parser.skipIgnorable();
  }
  return nodes;
}

// ---------------------------------------------------------------------------
// Lexer
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Parser recursivo
// ---------------------------------------------------------------------------

class _Parser {
  final List<Token> tokens;
  int pos = 0;

  _Parser(this.tokens);

  bool get isDone => tokens[pos].type == TokType.eof;
  Token get current => tokens[pos];

  /// Pula `const`/`return`/`new` antes de uma expressão.
  ///
  /// NAO pode pular `child`/`children`: sao nomes de argumento, e pular
  /// quebrava `child: Text(...)` — o parser comia o nome e via `: Text`
  /// como valor, perdendo o filho.
  void skipIgnorable() {
    while (!isDone) {
      final t = current;
      if (t.type == TokType.ident &&
          const {'const', 'return', 'new', 'build'}.contains(t.value)) {
        pos++;
        continue;
      }
      break;
    }
  }

  /// Lê uma expressão de widget: `Nome(args)` ou `Nome(...)`.
  Node parseWidgetExpression() {
    skipIgnorable();

    // Pula `Builder(builder: (context) =>` e similares até o widget real.
    if (current.type == TokType.ident && current.value == 'Builder' && _peekIsPunct('(')) {
      // tenta entrar dentro do builder
      final save = pos;
      pos++; // (
      while (!isDone && current.value != '=>') {
        pos++;
      }
      if (!isDone) {
        pos++; // =>
        final r = parseWidgetExpression();
        return r;
      }
      pos = save;
    }

    if (current.type != TokType.ident) {
      throw ParseError('Esperava um nome de widget, achei "${current.value}"', current.pos);
    }

    final name = _readDottedName();
    skipIgnorable();

    if (!_peekIsPunct('(')) {
      // Identificador solto (ex.: `context`) — não é widget.
      throw ParseError('Esperava "(" depois de $name', current.pos);
    }

    pos++; // consome '('

    final args = <String, Value>{};
    final positional = <Value>[];
    final children = <Node>[];

    while (!isDone && !_peekIsPunct(')')) {
      skipIgnorable();
      if (_peekIsPunct(',')) {
        pos++;
        continue;
      }
      if (isDone || _peekIsPunct(')')) break;

      // Argumento nomeado: `nome: valor`
      if (current.type == TokType.ident && _peekIsPunct(':', offset: 1)) {
        final key = current.value;
        pos += 2;

        // `children: [...]`
        if (_peekIsPunct('[')) {
          pos++;
          while (!isDone && !_peekIsPunct(']')) {
            skipIgnorable();
            if (_peekIsPunct(',')) {
              pos++;
              continue;
            }
            if (_peekIsPunct(']')) break;
            try {
              children.add(parseWidgetExpression());
            } catch (_) {
              _skipToCommaOrClose();
            }
            skipIgnorable();
            if (_peekIsPunct(',')) pos++;
          }
          if (_peekIsPunct(']')) pos++;
          continue;
        }

        // Um widget como valor: `child: Text('x')`.
        // Só tenta como widget se houver um "(" depois do nome — assim
        // `padding: 12` e `color: Colors.blue` continuam sendo valores.
        final childStart = pos;
        if (current.type == TokType.ident &&
            _looksLikeWidgetCall() &&
            !_isValueHelper(current.value)) {
          try {
            final child = parseWidgetExpression();
            children.add(child);
            args[key] = RawValue(child.name);
            continue;
          } catch (_) {
            pos = childStart;
            children.removeLast();
          }
        }
        args[key] = _parseValue();
        continue;
      }

      // Posicional: `Text('oi')`
      positional.add(_parseValue());
    }

    if (_peekIsPunct(')')) pos++;

    return Node(name, args, children, positional: positional);
  }


  /// `Text('x')` -> true; `Colors.blue` / `context` -> false.
  bool _looksLikeWidgetCall() {
    var i = pos;
    // nome possivelmente pontuado
    while (i < tokens.length && tokens[i].type == TokType.ident) {
      i++;
      if (i < tokens.length && tokens[i].type == TokType.punct && tokens[i].value == '.') {
        i++;
        continue;
      }
      break;
    }
    return i < tokens.length &&
        tokens[i].type == TokType.punct &&
        tokens[i].value == '(';
  }

  /// `EdgeInsets.all(...)`, `BorderRadius.circular(...)` e `Colors.x` sao
  /// valores, nao widgets — mesmo tendo "(" depois do nome.
  bool _isValueHelper(String name) {
    return const {
      'EdgeInsets', 'EdgeInsetsGeometry', 'EdgeInsetsDirectional',
      'BorderRadius', 'Radius', 'Color', 'Colors', 'TextStyle', 'BoxDecoration',
      'BoxShadow', 'Alignment', 'Offset', 'Size', 'Duration', 'Curves',
      'Border', 'BorderSide', 'LinearGradient', 'FontWeight',
    }.contains(name);
  }

  /// Lê um valor simples (string, número, bool, null, enum, lista).
  Value _parseValue() {
    final t = current;

    if (t.type == TokType.string) {
      pos++;
      return StringValue(t.value);
    }
    if (t.type == TokType.number) {
      pos++;
      return NumberValue(double.tryParse(t.value) ?? 0);
    }
    if (t.type == TokType.ident) {
      final save = pos;
      final raw0 = _readDottedName();
      // `EdgeInsets.all(12)` e `Colors.blue`: depois do nome pontuado pode
      // haver uma chamada. `Text('x')` normalmente já foi tratado como nó
      // antes de chegar aqui.
      final raw = raw0;
      if (_peekIsPunct('(')) {
        final start = save;
        var depth = 0;
        while (!isDone) {
          if (_peekIsPunct('(')) depth++;
          if (_peekIsPunct(')')) {
            depth--;
            pos++;
            if (depth == 0) break;
            continue;
          }
          pos++;
        }
        final raw2 = tokens.sublist(start, pos).map((x) => x.value).join();
        return RawValue(raw2);
      }
      if (raw == 'true') return const BoolValue(true);
      if (raw == 'false') return const BoolValue(false);
      if (raw == 'null') return const NullValue();
      return RawValue(raw);
    }

    // Expressão desconhecida: consome até vírgula ou parêntese de fechamento.
    final start = pos;
    var depth = 0;
    while (!isDone) {
      if (_peekIsPunct('(') || _peekIsPunct('[')) depth++;
      if (_peekIsPunct(')') || _peekIsPunct(']')) {
        if (depth == 0) break;
        depth--;
      }
      if (_peekIsPunct(',') && depth == 0) break;
      pos++;
    }
    return RawValue(tokens.sublist(start, pos).map((x) => x.value).join());
  }

  String _readDottedName() {
    final buf = StringBuffer();
    while (!isDone && current.type == TokType.ident) {
      buf.write(current.value);
      pos++;
      if (_peekIsPunct('.')) {
        buf.write('.');
        pos++;
      } else {
        break;
      }
    }
    return buf.toString();
  }

  bool _peekIsPunct(String p, {int offset = 0}) {
    final idx = pos + offset;
    if (idx >= tokens.length) return false;
    return tokens[idx].type == TokType.punct && tokens[idx].value == p;
  }

  void _skipToCommaOrClose() {
    var depth = 0;
    while (!isDone) {
      if (_peekIsPunct('(') || _peekIsPunct('[')) depth++;
      if (_peekIsPunct(')') || _peekIsPunct(']')) {
        if (depth == 0) return;
        depth--;
      }
      if (_peekIsPunct(',') && depth == 0) return;
      pos++;
    }
  }
}
