import 'package:flutter/material.dart';

import '../content/exercise.dart';
import '../content/lessons.dart';

class LessonScreen extends StatefulWidget {
  final int lessonIndex;

  const LessonScreen({
    super.key,
    this.lessonIndex = 0,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late Lesson _lesson;
  int _exerciseIndex = 0;
  int? _chosenOption;
  List<String> _chosenOrder = [];
  final TextEditingController _freeController = TextEditingController();
  ExerciseResult? _result;
  bool? _correct;
  List<CodeBlock> _shuffledBlocks = [];
  int? _savedXp;

  @override
  void initState() {
    super.initState();
    _lesson = allLessons[widget.lessonIndex];
    _freeController.text = _lesson.exercises[_exerciseIndex].template;
    _shuffleBlocks();
  }

  @override
  void dispose() {
    _freeController.dispose();
    super.dispose();
  }

  void _shuffleBlocks() {
    final exercise = _lesson.exercises[_exerciseIndex];
    if (exercise.kind == ExerciseKind.blocks) {
      final blocks = List<CodeBlock>.from(exercise.blocks);
      blocks.shuffle();
      _shuffledBlocks = blocks;
    }
  }

  Exercise get _exercise => _lesson.exercises[_exerciseIndex];

  void _reset() {
    setState(() {
      _chosenOption = null;
      _chosenOrder = [];
      _result = null;
      _correct = null;
      _freeController.text = _exercise.template;
      _shuffleBlocks();
    });
  }

  void _check() {
    final r = checkExercise(
      _exercise,
      chosenOption: _chosenOption,
      chosenOrder: _chosenOrder,
      freeText: _freeController.text,
    );

    final bool ok;
    switch (_exercise.kind) {
      case ExerciseKind.gap:
        ok = _chosenOption == _exercise.correctOption;
      case ExerciseKind.blocks:
        ok = _listEquals(_chosenOrder, _exercise.correctOrder);
      case ExerciseKind.free:
        ok = r.ok && r.output.isNotEmpty;
    }

    setState(() {
      _result = r;
      _correct = ok;
    });

    // Award XP on first correct answer
    if (ok && _savedXp == null) {
      _savedXp = 10;
      _awardXp();
    }
  }

  Future<void> _awardXp() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('+10 XP!'),
          backgroundColor: Color(0xFF6750A4),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _next() {
    if (_exerciseIndex + 1 >= _lesson.exercises.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lição concluída! 🎉')),
      );
      return;
    }
    setState(() {
      _exerciseIndex++;
      _chosenOption = null;
      _chosenOrder = [];
      _result = null;
      _correct = null;
      _savedXp = null;
      _freeController.text = _exercise.template;
      _shuffleBlocks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_exerciseIndex + 1) / _lesson.exercises.length;
    final isLast = _exerciseIndex + 1 >= _lesson.exercises.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_lesson.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Exercise number
            Text(
              'Exercício ${_exerciseIndex + 1} de ${_lesson.exercises.length}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            // Prompt
            Text(
              _exercise.prompt,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),

            // Exercise widget based on kind
            _buildExerciseWidget(),

            const SizedBox(height: 24),

            // Result/feedback
            if (_result != null) _buildResult(),

            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Limpar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _result == null ? _check : (isLast ? null : _next),
                    icon: Icon(_result == null ? Icons.check : (isLast ? Icons.celebration : Icons.navigate_next)),
                    label: Text(_result == null ? 'Verificar' : (isLast ? 'Concluído!' : 'Próximo')),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: _result == null ? const Color(0xFF6750A4) : (_correct == true ? Colors.green : Colors.red),
                    ),
                  ),
                ),
              ],
            ),

            if (_correct == true) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.green[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _exercise.explanation,
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseWidget() {
    switch (_exercise.kind) {
      case ExerciseKind.gap:
        return _buildGapExercise();
      case ExerciseKind.blocks:
        return _buildBlocksExercise();
      case ExerciseKind.free:
        return _buildFreeExercise();
    }
  }

  Widget _buildGapExercise() {
    final parts = _exercise.template.split('___');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (parts.length > 1 && parts[0].isNotEmpty)
          SelectableText(
            parts[0],
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _exercise.options.asMap().entries.map((entry) {
            final idx = entry.key;
            final option = entry.value;
            final isSelected = _chosenOption == idx;
            return ChoiceChip(
              label: Text(option, style: const TextStyle(fontFamily: 'monospace')),
              selected: isSelected,
              onSelected: (_) => setState(() => _chosenOption = idx),
              selectedColor: const Color(0xFF6750A4).withValues(alpha: 0.2),
              checkmarkColor: const Color(0xFF6750A4),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF6750A4) : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        if (parts.length > 1 && parts[1].isNotEmpty) ...[
          const SizedBox(height: 8),
          SelectableText(
            parts[1],
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          ),
        ],
      ],
    );
  }

  Widget _buildBlocksExercise() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Available blocks
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _shuffledBlocks.map((block) {
            final isUsed = _chosenOrder.contains(block.id);
            return Draggable<CodeBlock>(
              data: block,
              feedback: Material(
                color: isUsed ? Colors.grey[300] : const Color(0xFF6750A4).withValues(alpha: 0.1),
                elevation: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    block.label,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: isUsed ? Colors.grey : const Color(0xFF6750A4),
                    ),
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _buildBlockChip(block, isUsed),
              ),
              child: _buildBlockChip(block, isUsed),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Drop zone / assembled code
        DragTarget<CodeBlock>(
          builder: (context, candidateData, rejectedData) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: candidateData.isNotEmpty ? const Color(0xFF6750A4).withValues(alpha: 0.1) : (Colors.grey[100] ?? Colors.grey),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: candidateData.isNotEmpty ? const Color(0xFF6750A4) : (Colors.grey[300] ?? Colors.grey),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seu código:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (_chosenOrder.isEmpty)
                    Text(
                      'Arraste os blocos aqui na ordem correta',
                      style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic),
                    )
                  else
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _chosenOrder.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final blockId = entry.value;
                        final block = _shuffledBlocks.firstWhere((b) => b.id == blockId, orElse: () => CodeBlock('', ''));
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6750A4).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                block.label,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => setState(() => _chosenOrder.removeAt(idx)),
                                child: const Icon(Icons.close, size: 14),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
          onAcceptWithDetails: (details) {
            setState(() {
              _chosenOrder.add(details.data.id);
            });
          },
        ),
      ],
    );
  }

  Widget _buildBlockChip(CodeBlock block, bool isUsed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isUsed ? Colors.grey[200] : const Color(0xFF6750A4).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUsed ? Colors.grey[400]! : const Color(0xFF6750A4),
        ),
      ),
      child: Text(
        block.label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: isUsed ? Colors.grey[600] : const Color(0xFF6750A4),
        ),
      ),
    );
  }

  Widget _buildFreeExercise() {
    return TextField(
      controller: _freeController,
      maxLines: 8,
      minLines: 8,
      decoration: InputDecoration(
        hintText: 'Digite seu código aqui...',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
    );
  }

  Widget _buildResult() {
    if (_correct == true) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Correto! ✓',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (_result!.output.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Saída:',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _result!.output.map((line) {
                    return Text(
                      line,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cancel, color: Colors.red[700]),
                const SizedBox(width: 8),
                Text(
                  'Tente novamente',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (_result != null && _result!.messages.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _result!.messages.first,
                style: TextStyle(color: Colors.red[700]),
              ),
            ],
          ],
        ),
      );
    }
  }
}