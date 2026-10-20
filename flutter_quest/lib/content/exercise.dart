// Exercícios no estilo Duolingo: blocos, lacunas e código livre.
//
// A ideia central: nos dois primeiros tipos o aluno NÃO digita código —
// ele monta ou completa. O resultado final ainda é código Dart válido,
// então roda no mesmo avaliador da lógica. Validação fica trivial e a
// experiência fica guiada.

enum ExerciseKind {
  /// Toca numa opção para preencher a lacuna de um código pronto.
  gap,

  /// Arrasta (ou toca) peças para montar o código inteiro.
  blocks,

  /// Digita no editor. Só nas lições finais.
  free,
}

/// Uma peça de bloco, como o aluno vê.
class CodeBlock {
  final String id;
  final String label;

  const CodeBlock(this.id, this.label);
}

class Exercise {
  final int id;
  final ExerciseKind kind;
  final String prompt;

  /// Código mostrado, com `___` onde falta algo (kind == gap).
  final String template;

  /// Opções da lacuna (kind == gap).
  final List<String> options;

  /// Índice da opção correta em [options].
  final int correctOption;

  /// Peças disponíveis (kind == blocks).
  final List<CodeBlock> blocks;

  /// Ordem correta dos ids em [blocks] (kind == blocks).
  final List<String> correctOrder;

  /// Explicação mostrada depois de acertar.
  final String explanation;

  const Exercise.gap({
    required this.id,
    required this.prompt,
    required this.template,
    required this.options,
    required this.correctOption,
    required this.explanation,
  })  : kind = ExerciseKind.gap,
        blocks = const [],
        correctOrder = const [];

  const Exercise.blocks({
    required this.id,
    required this.prompt,
    required this.blocks,
    required this.correctOrder,
    required this.explanation,
  })  : kind = ExerciseKind.blocks,
        template = '',
        options = const [],
        correctOption = -1;

  const Exercise.free({
    required this.id,
    required this.prompt,
    required this.template,
    required this.explanation,
  })  : kind = ExerciseKind.free,
        blocks = const [],
        correctOrder = const [],
        options = const [],
        correctOption = -1;

  /// O código que o aluno produziu, pronto para rodar.
  ///
  /// - gap: template com `___` trocado pela opção escolhida
  /// - blocks: peças na ordem escolhida, separadas por espaço
  /// - free: o próprio texto digitado
  String codeFor({
    int? chosenOption,
    List<String>? chosenOrder,
    String? freeText,
  }) {
    switch (kind) {
      case ExerciseKind.gap:
        final option = (chosenOption != null &&
                chosenOption >= 0 &&
                chosenOption < options.length)
            ? options[chosenOption]
            : '___';
        return _fillTemplate(template, option);

      case ExerciseKind.blocks:
        final order = chosenOrder ?? const <String>[];
        final byId = {for (final b in blocks) b.id: b.label};
        final parts = order.map((id) => byId[id] ?? '').where((s) => s.isNotEmpty);
        return parts.join(' ');

      case ExerciseKind.free:
        return freeText ?? template;
    }
  }

  /// Troca `___` pela opção, respeitando espaçamento em volta.
  static String _fillTemplate(String template, String option) {
    if (!template.contains('___')) return template;
    return template.replaceAll('___', option);
  }
}
