enum ExerciseKind { gap, blocks, free }

/// Bloco de código usado nos exercícios de montagem.
class CodeBlock {
  final String id;
  final String label;

  const CodeBlock({required this.id, required this.label});
}

/// Entidade que representa um exercício.
class Exercise {
  final String id;
  final ExerciseKind kind;
  final String prompt;
  final String template;
  final List<String> options;
  final int correctOption;
  final List<CodeBlock> blocks;
  final List<String> correctOrder;
  final String? explanation;

  const Exercise({
    required this.id,
    required this.kind,
    required this.prompt,
    required this.template,
    this.options = const [],
    this.correctOption = -1,
    this.blocks = const [],
    this.correctOrder = const [],
    this.explanation,
  });

  bool get isGap => kind == ExerciseKind.gap;
  bool get isBlocks => kind == ExerciseKind.blocks;
  bool get isFree => kind == ExerciseKind.free;

  Exercise copyWith({
    String? id,
    ExerciseKind? kind,
    String? prompt,
    String? template,
    List<String>? options,
    int? correctOption,
    List<CodeBlock>? blocks,
    List<String>? correctOrder,
    String? explanation,
  }) {
    return Exercise(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      prompt: prompt ?? this.prompt,
      template: template ?? this.template,
      options: options ?? this.options,
      correctOption: correctOption ?? this.correctOption,
      blocks: blocks ?? this.blocks,
      correctOrder: correctOrder ?? this.correctOrder,
      explanation: explanation ?? this.explanation,
    );
  }
}