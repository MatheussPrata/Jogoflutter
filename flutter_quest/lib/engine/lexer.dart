// Lexer compartilhado: widgets (parser.dart) e lógica (logic.dart) usam o
// mesmo tokenizador. Duas cópias divergiriam.

enum TokType { ident, string, number, punct, eof }

class Token {
  final TokType type;
  final String value;
  final int pos;
  const Token(this.type, this.value, this.pos);
  @override
  String toString() => '$type($value)@$pos';
}

List<Token> tokenize(String src) {
  final tokens = <Token>[];
  var i = 0;
  final n = src.length;

  while (i < n) {
    final c = src[i];

    // Espaços
    if (c == ' ' || c == '\n' || c == '\r' || c == '\t') {
      i++;
      continue;
    }

    // Comentários de linha
    if (c == '/' && i + 1 < n && src[i + 1] == '/') {
      while (i < n && src[i] != '\n') {
        i++;
      }
      continue;
    }

    // Comentários de bloco
    if (c == '/' && i + 1 < n && src[i + 1] == '*') {
      i += 2;
      while (i + 1 < n && !(src[i] == '*' && src[i + 1] == '/')) {
        i++;
      }
      i = (i + 1).clamp(0, n);
      continue;
    }

    // Strings
    if (c == "'" || c == '"') {
      final quote = c;
      final start = i;
      i++;
      final buf = StringBuffer();
      while (i < n && src[i] != quote) {
        if (src[i] == '\\' && i + 1 < n) {
          i++;
          final esc = src[i];
          buf.write(switch (esc) {
            'n' => '\n',
            't' => '\t',
            _ => esc,
          });
        } else {
          buf.write(src[i]);
        }
        i++;
      }
      if (i >= n) {
        throw ParseError('String não terminada', start);
      }
      i++; // fecha a string
      tokens.add(Token(TokType.string, buf.toString(), start));
      continue;
    }

    // Números
    if (RegExp(r'[0-9]').hasMatch(c)) {
      final start = i;
      while (i < n && RegExp(r'[0-9.]').hasMatch(src[i])) {
        i++;
      }
      tokens.add(Token(TokType.number, src.substring(start, i), start));
      continue;
    }

    // Identificadores (inclui `_` e `.` para nomes compostos)
    if (RegExp(r'[A-Za-z_]').hasMatch(c)) {
      final start = i;
      while (i < n && RegExp(r'[A-Za-z0-9_]').hasMatch(src[i])) {
        i++;
      }
      tokens.add(Token(TokType.ident, src.substring(start, i), start));
      continue;
    }

    // Pontuação e operadores
    tokens.add(Token(TokType.punct, c, i));
    i++;
  }

  tokens.add(Token(TokType.eof, '', n));
  return tokens;
}

/// Erro de sintaxe. Carrega a posição para destacar na linha certa.
class ParseError implements Exception {
  final String message;
  final int position;
  ParseError(this.message, this.position);
  @override
  String toString() => 'Erro na posição $position: $message';
}
