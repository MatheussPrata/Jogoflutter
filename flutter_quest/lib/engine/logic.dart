// Avaliador de lógica: executa o subconjunto de Dart da Etapa 1.
//
// O aluno escreve:
//   final preco = 29.90;
//   final desconto = preco * 0.1;
//   print(preco - desconto);
//
// E o jogo mostra a saída e o valor das variáveis.
//
// Mesmo lexer do parser de widgets — só muda o que se faz com os tokens.

import 'lexer.dart';

/// Uma variável depois da execução.
class VarValue {
  final String name;
  final Object? value;
  const VarValue(this.name, this.value);
}

/// Resultado da execução de um programa.
class RunResult {
  final bool ok;
  final List<String> output;
  final List<VarValue> variables;
  final String? error;

  const RunResult({
    required this.ok,
    this.output = const [],
    this.variables = const [],
    this.error,
  });

  static RunResult success(List<String> output, List<VarValue> vars) =>
      RunResult(ok: true, output: output, variables: vars);

  static RunResult failure(String error) => RunResult(ok: false, error: error);
}

/// Executa o código e devolve saída + variáveis.
RunResult runLogic(String source) {
  try {
    final tokens = tokenize(source);
    final interp = _Interpreter(tokens);
    return interp.run();
  } on ParseError catch (e) {
    return RunResult.failure(e.message);
  } on _RuntimeProblem catch (e) {
    return RunResult.failure(e.message);
  } catch (e) {
    return RunResult.failure('Não consegui rodar: $e');
  }
}

class _RuntimeProblem implements Exception {
  final String message;
  _RuntimeProblem(this.message);
  @override
  String toString() => message;
}

// ---------------------------------------------------------------------------
// Interpretador
// ---------------------------------------------------------------------------

class _Interpreter {
  final List<Token> tokens;
  int pos = 0;

  final Map<String, Object?> vars = {};
  final List<String> output = [];

  _Interpreter(this.tokens);

  bool get isDone => tokens[pos].type == TokType.eof;
  Token get current => tokens[pos];

  RunResult run() {
    while (!isDone) {
      _skipIgnorable();
      if (isDone) break;

      // `void main() { ... }`: o corpo da função é o programa. Ignoramos a
      // assinatura e as chaves externas — o aluno pode escrever as duas
      // formas (com ou sem main) e o resultado é o mesmo.
      if (_isMainDeclaration()) {
        _enterMainBody();
        continue;
      }

      // Chaves soltas (fim do corpo de main).
      if (current.value == '}') {
        pos++;
        continue;
      }

      _statement();
    }
    final list = vars.entries.map((e) => VarValue(e.key, e.value)).toList();
    return RunResult.success(output, list);
  }

  /// `void main()`, `main()`, `void main(List<String> args)`...
  bool _isMainDeclaration() {
    var i = pos;
    // tipo de retorno opcional
    if (i < tokens.length && tokens[i].type == TokType.ident) {
      final v = tokens[i].value;
      if (v == 'void' || v == 'int' || v == 'Future' || v == 'dynamic') {
        i++;
        if (i < tokens.length && tokens[i].value == '<') {
          while (i < tokens.length && tokens[i].value != '>') {
            i++;
          }
          if (i < tokens.length) i++;
        }
      }
    }
    if (i >= tokens.length) return false;
    if (tokens[i].type != TokType.ident || tokens[i].value != 'main') return false;
    i++;
    if (i >= tokens.length || tokens[i].value != '(') return false;
    return true;
  }

  /// Consome `void main(...) {` e deixa o cursor no primeiro statement.
  void _enterMainBody() {
    while (!isDone && current.value != '(') {
      pos++;
    }
    var depth = 0;
    while (!isDone) {
      if (current.value == '(') depth++;
      if (current.value == ')') {
        depth--;
        if (depth == 0) {
          pos++;
          break;
        }
      }
      pos++;
    }
    // pula até a chave de abertura
    while (!isDone && current.value != '{') {
      pos++;
    }
    if (!isDone) pos++;
  }

  void _skipIgnorable() {
    while (!isDone) {
      final v = current.value;
      if (current.type == TokType.punct && v == ';') {
        pos++;
        continue;
      }
      break;
    }
  }

  void _statement() {
    _skipIgnorable();
    final t = current;

    // `final x = ...` / `var x = ...`
    if (t.type == TokType.ident && (t.value == 'final' || t.value == 'var')) {
      pos++;
      if (current.type != TokType.ident) {
        throw ParseError('Esperava o nome da variável', current.pos);
      }
      final name = current.value;
      pos++;
      _expect('=');
      final value = _expression();
      vars[name] = value;
      return;
    }

    // `print(...)`
    if (t.type == TokType.ident &&
        t.value == 'print' &&
        pos + 1 < tokens.length &&
        tokens[pos + 1].value == '(') {
      pos++;
      _expect('(');
      final value = _expression();
      _expect(')');
      output.add(_format(value));
      return;
    }

    // Expressão solta
    _expression();
  }

  // -- expressões ----------------------------------------------------------

  Object? _expression() {
    var left = _term();
    while (!isDone && _isOp(current.value, const ['+', '-'])) {
      final op = current.value;
      pos++;
      final right = _term();
      left = _applyArith(op, left, right);
    }
    return left;
  }

  Object? _term() {
    var left = _factor();
    while (!isDone && _isOp(current.value, const ['*', '/', '%'])) {
      final op = current.value;
      pos++;
      final right = _factor();
      left = _applyArith(op, left, right);
    }
    return left;
  }

  Object? _factor() {
    _skipIgnorable();
    final t = current;

    if (t.type == TokType.number) {
      pos++;
      // Literal escrito com ponto continua decimal: 12.00 imprime "12.00".
      // Literal inteiro continua int: 10 imprime "10".
      final parsed = double.tryParse(t.value) ?? 0;
      final writtenDecimal = t.value.contains('.');
      if (!writtenDecimal && parsed == parsed.roundToDouble()) {
        return parsed.toInt();
      }
      return parsed;
    }

    if (t.type == TokType.string) {
      pos++;
      return t.value;
    }

    if (t.type == TokType.punct && t.value == '(') {
      pos++;
      final v = _expression();
      _expect(')');
      return v;
    }

    if (t.type == TokType.punct && t.value == '-') {
      pos++;
      final v = _factorAsNumber();
      return -v;
    }

    if (t.type == TokType.ident) {
      final name = t.value;
      pos++;
      if (name == 'true') return true;
      if (name == 'false') return false;
      if (name == 'null') return null;
      if (!vars.containsKey(name)) {
        throw _RuntimeProblem('A variável "$name" não existe.');
      }
      return vars[name];
    }

    throw ParseError('Não entendi "${t.value}"', t.pos);
  }

  double _factorAsNumber() {
    final v = _factor();
    if (v is num) return v.toDouble();
    throw _RuntimeProblem('Esperava um número.');
  }

  Object _applyArith(String op, Object? a, Object? b) {
    // Concatenação de texto
    if (op == '+' && (a is String || b is String)) {
      return '${_format(a)}${_format(b)}';
    }
    final na = _asNum(a);
    final nb = _asNum(b);
    return switch (op) {
      '+' => _norm(na + nb),
      '-' => _norm(na - nb),
      '*' => _norm(na * nb),
      // Divisao sempre devolve decimal: 10 / 4 = 2.5, nunca 2.
      '/' => na / nb,
      '%' => _norm(na % nb),
      _ => throw _RuntimeProblem('Operador desconhecido: $op'),
    };
  }

  double _asNum(Object? v) {
    if (v is num) return v.toDouble();
    throw _RuntimeProblem('Esperava um número, achei "${_format(v)}".');
  }

  Object _norm(double v) => v == v.roundToDouble() ? v.toInt() : v;

  bool _isOp(String value, List<String> ops) =>
      current.type == TokType.punct && ops.contains(value);

  bool _peek(String p) => pos < tokens.length && tokens[pos].value == p;

  void _expect(String p) {
    if (!_peek(p)) {
      throw ParseError('Esperava "$p", achei "${current.value}"', current.pos);
    }
    pos++;
  }

  String _format(Object? v) {
    if (v == null) return 'null';
    if (v is double) return v.toStringAsFixed(2);
    return v.toString();
  }
}
