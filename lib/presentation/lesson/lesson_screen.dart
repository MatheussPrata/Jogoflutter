import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/lesson_provider.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/exercise.dart';

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
  bool? _correct;

  @override
  void initState() {
    super.initState();
    final lessonProvider = context.read<LessonProvider>();
    _lesson = lessonProvider.getLesson(widget.lessonIndex) ?? lessonProvider.lessons.first;
    _freeController.text = _lesson.exercises[_exerciseIndex].template;
  }

  @override
  void dispose() {
    _freeController.dispose();
    super.dispose();
  }

  Exercise get _exercise => _lesson.exercises[_exerciseIndex];

  void _reset() {
    setState(() {
      _chosenOption = null;
      _chosenOrder = [];
      _correct = null;
      _freeController.text = _exercise.template;
    });
  }

  void _check() {
    final bool ok;
    switch (_exercise.kind) {
      case ExerciseKind.gap:
        ok = _chosenOption == _exercise.correctOption;
      case ExerciseKind.blocks:
        ok = _listEquals(_chosenOrder, _exercise.correctOrder);
      case ExerciseKind.free:
        ok = _freeController.text.trim().isNotEmpty;
    }

    setState(() {
      _correct = ok;
    });

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Correto! +10 XP'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
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
      _correct = null;
      _freeController.text = _exercise.template;
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
            if (_correct != null) _buildResult(),

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
                    onPressed: _correct == null ? _check : (isLast ? null : _next),
                    icon: Icon(_correct == null ? Icons.check : (isLast ? Icons.celebration : Icons.navigate_next)),
                    label: Text(_correct == null ? 'Verificar' : (isLast ? 'Concluído!' : 'Próximo')),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: _correct == null ? Theme.of(context).colorScheme.primary : (_correct == true ? Colors.green : Colors.red),
                    ),
                  ),
                ),
              ],
            ),

            if (_correct == true && _exercise.explanation != null) ...[
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
                        _exercise.explanation!,
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
              selectedColor: Theme.of(context).colorScheme.primary.withOpacity( 0.2),
              checkmarkColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black,
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
          children: _exercise.blocks.map((block) {
            final isUsed = _chosenOrder.contains(block.id);
            return Draggable<CodeBlock>(
              data: block,
              feedback: Material(
                color: isUsed ? Colors.grey[300] : Theme.of(context).colorScheme.primary.withOpacity( 0.1),
                elevation: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    block.label,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: isUsed ? Colors.grey : Theme.of(context).colorScheme.primary,
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
                color: candidateData.isNotEmpty ? Theme.of(context).colorScheme.primary.withOpacity( 0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: candidateData.isNotEmpty ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
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
                        final block = _exercise.blocks.firstWhere((b) => b.id == blockId, orElse: () => const CodeBlock(id: '', label: ''));
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity( 0.1),
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
        color: isUsed ? Colors.grey[200] : Theme.of(context).colorScheme.primary.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUsed ? Colors.grey[400]! : Theme.of(context).colorScheme.primary,
        ),
      ),
      child: Text(
        block.label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: isUsed ? Colors.grey[600] : Theme.of(context).colorScheme.primary,
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
          ],
        ),
      );
    }
  }
}