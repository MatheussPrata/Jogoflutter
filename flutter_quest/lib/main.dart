import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'content/exercise.dart';
import 'content/lessons.dart';

void main() {
  runApp(const FlutterQuestApp());
}

class FlutterQuestApp extends StatelessWidget {
  const FlutterQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Quest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
        useMaterial3: true,
      ),
      home: const LessonScreen(),
    );
  }
}

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final lesson = allLessons.first;

  int index = 0;
  int? chosenOption;
  List<String> chosenOrder = [];
  late TextEditingController freeController;

  /// Peças na ordem exibida (embaralhada). Recalculada ao trocar de exercício
  /// para a mesma peça não cair sempre na mesma posição.
  List<CodeBlock> shuffledBlocks = [];

  ExerciseResult? result;
  bool? correct;

  Exercise get exercise => lesson.exercises[index];

  @override
  void initState() {
    super.initState();
    freeController = TextEditingController(text: exercise.template);
    _shuffleBlocks();
  }

  /// Embaralha as peças. Usa semente baseada no exercício para não mudar
  /// a cada rebuild, mas ser diferente entre exercícios.
  void _shuffleBlocks() {
    final blocks = List<CodeBlock>.from(exercise.blocks);
    blocks.shuffle(math.Random(exercise.id * 7919 + index));
    shuffledBlocks = blocks;
  }

  @override
  void dispose() {
    freeController.dispose();
    super.dispose();
  }

  void reset() {
    setState(() {
      chosenOption = null;
      chosenOrder = [];
      result = null;
      correct = null;
      freeController.text = exercise.template;
    });
  }

  void check() {
    final r = checkExercise(
      exercise,
      chosenOption: chosenOption,
      chosenOrder: chosenOrder,
      freeText: freeController.text,
    );

    // Critério de acerto por tipo: a saída precisa ser coerente.
    final bool ok;
    switch (exercise.kind) {
      case ExerciseKind.gap:
        ok = chosenOption == exercise.correctOption;
      case ExerciseKind.blocks:
        ok = _listEquals(chosenOrder, exercise.correctOrder);
      case ExerciseKind.free:
        ok = r.ok && r.output.isNotEmpty;
    }

    setState(() {
      result = r;
      correct = ok;
    });
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void next() {
    if (index + 1 >= lesson.exercises.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lição concluída! 🎉')),
      );
      return;
    }
    setState(() {
      index++;
      chosenOption = null;
      chosenOrder = [];
      result = null;
      correct = null;
      freeController.text = exercise.template;
      _shuffleBlocks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (index + 1) / lesson.exercises.length,
            minHeight: 6,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Exercício ${index + 1} de ${lesson.exercises.length}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              exercise.prompt,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildBody(),
            const SizedBox(height: 16),
            if (correct != null) _feedbackBox(),
            const SizedBox(height: 12),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (exercise.kind) {
      case ExerciseKind.gap:
        return _gapBody();
      case ExerciseKind.blocks:
        return _blocksBody();
      case ExerciseKind.free:
        return _freeBody();
    }
  }

  // -- lacuna --------------------------------------------------------------

  Widget _gapBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            exercise.codeFor(chosenOption: chosenOption),
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < exercise.options.length; i++)
              ChoiceChip(
                label: Text(exercise.options[i]),
                selected: chosenOption == i,
                onSelected: (_) => setState(() {
                  chosenOption = i;
                  correct = null;
                }),
              ),
          ],
        ),
      ],
    );
  }

  // -- blocos --------------------------------------------------------------

  Widget _blocksBody() {
    final available =
        shuffledBlocks.where((b) => !chosenOrder.contains(b.id)).toList();
    final byId = {for (final b in shuffledBlocks) b.id: b.label};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // área de montagem
        Container(
          constraints: const BoxConstraints(minHeight: 72),
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: chosenOrder.isEmpty
              ? const Text(
                  'Toque nas peças abaixo para montar o código',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                )
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final id in chosenOrder)
                      ActionChip(
                        label: Text(
                          byId[id] ?? '',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: const Color(0xFF3A3A3A),
                        onPressed: () => setState(() {
                          chosenOrder.remove(id);
                          correct = null;
                        }),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final block in available)
              ActionChip(
                label: Text(
                  block.label,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                onPressed: () => setState(() {
                  chosenOrder.add(block.id);
                  correct = null;
                }),
              ),
          ],
        ),
      ],
    );
  }

  // -- livre ---------------------------------------------------------------

  Widget _freeBody() {
    return TextField(
      controller: freeController,
      maxLines: 10,
      minLines: 6,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.5),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(12),
      ),
      onChanged: (_) => setState(() => correct = null),
    );
  }

  // -- feedback ------------------------------------------------------------

  Widget _feedbackBox() {
    final ok = correct == true;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ok ? Icons.check_circle : Icons.lightbulb_outline,
                color: ok ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                ok ? 'Certo!' : 'Quase!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ok ? Colors.green[800] : Colors.orange[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (ok)
            Text(exercise.explanation, style: const TextStyle(fontSize: 13))
          else ...[
            ...result!.messages.map(
              (m) => Text(m, style: const TextStyle(fontSize: 12)),
            ),
            if (result!.output.isNotEmpty)
              Text(
                'Saída: ${result!.output.join(" / ")}',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    final canCheck = switch (exercise.kind) {
      ExerciseKind.gap => chosenOption != null,
      ExerciseKind.blocks => chosenOrder.isNotEmpty,
      ExerciseKind.free => true,
    };

    if (correct == true) {
      return FilledButton(
        onPressed: next,
        child: Text(
          index + 1 >= lesson.exercises.length ? 'Concluir' : 'Continuar',
        ),
      );
    }

    return Row(
      children: [
        if (correct == false)
          OutlinedButton(
            onPressed: reset,
            child: const Text('Tentar de novo'),
          ),
        const Spacer(),
        FilledButton(
          onPressed: canCheck ? check : null,
          child: const Text('Verificar'),
        ),
      ],
    );
  }
}
