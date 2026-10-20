// Renderizador: transforma a árvore de [Node] em widgets Flutter.
//
// É o que faz o jogo existir: o aluno escreve texto, o parser monta a árvore,
// este arquivo desenha na tela.
//
// Limite consciente: só os widgets do subconjunto são renderizados. Um nome
// desconhecido vira um aviso cinza em vez de quebrar a tela — o aluno precisa
// entender o erro, não perder o progresso.

import 'package:flutter/material.dart';

import 'parser.dart';

/// Widget que desenha a árvore inteira, dentro de um contêiner com
/// rolagem e fundo, para parecer um "celular" no painel de preview.
class PreviewCanvas extends StatelessWidget {
  final Node? tree;
  final String? error;

  const PreviewCanvas({super.key, this.tree, this.error});

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return _ErrorBox(message: error!);
    }
    if (tree == null) {
      return const Center(
        child: Text(
          'Escreva algum widget para ver o resultado',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: renderNode(tree!, context),
    );
  }
}

/// Renderiza um nó e seus filhos.
Widget renderNode(Node node, BuildContext context) {
  final children = node.children.map((c) => renderNode(c, context)).toList();

  switch (node.name) {
    case 'Text':
      return Text(
        node.text ?? '',
        textAlign: _alignment(node),
        style: _textStyle(context, node),
      );

    case 'Center':
      return Center(child: _first(children));

    case 'Container':
      return Container(
        padding: _edgeInsets(node.args['padding']),
        margin: _edgeInsets(node.args['margin']),
        decoration: _decoration(node, context),
        child: _first(children),
      );

    case 'Padding':
      return Padding(
        padding: _edgeInsets(node.args['padding']) ?? const EdgeInsets.all(8),
        child: _first(children),
      );

    case 'Row':
      return Row(
        mainAxisAlignment: _mainAxis(node),
        crossAxisAlignment: _crossAxis(node),
        children: children.isEmpty ? [const SizedBox.shrink()] : children,
      );

    case 'Column':
      return Column(
        mainAxisAlignment: _mainAxis(node),
        crossAxisAlignment: _crossAxis(node),
        mainAxisSize: MainAxisSize.min,
        children: children.isEmpty ? [const SizedBox.shrink()] : children,
      );

    case 'Expanded':
      return Expanded(child: _first(children));

    case 'Flexible':
      return Flexible(child: _first(children));

    case 'Spacer':
      return const Spacer();

    case 'SizedBox':
      return SizedBox(
        width: _number(node.args['width']),
        height: _number(node.args['height']),
        child: _first(children),
      );

    case 'Divider':
      return const Divider();

    case 'Icon':
      return Icon(_icon(node.args['icon']), color: _color(node.args['color']));

    case 'Card':
      return Card(child: _first(children));

    case 'ListView':
      // Uma ListView dentro do preview precisa de altura finita.
      return SizedBox(
        height: 240,
        child: ListView(children: children),
      );

    case 'SafetyArea':
    case 'MediaQuery':
      return _first(children);

    default:
      return _UnknownWidget(name: node.name);
  }
}

Widget _first(List<Widget> children) {
  return children.isEmpty ? const SizedBox.shrink() : children.first;
}

/// Widget desconhecido: explica em vez de quebrar.
class _UnknownWidget extends StatelessWidget {
  final String name;
  const _UnknownWidget({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        border: Border.all(color: const Color(0xFFFFB74D)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.help_outline, size: 16, color: Color(0xFFE65100)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$name ainda não é suportado aqui',
              style: const TextStyle(fontSize: 12, color: Color(0xFFE65100)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      color: const Color(0xFFFFEBEE),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xFFC62828)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: Color(0xFFB71C1C)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Conversão de propriedades
// ---------------------------------------------------------------------------

TextAlign? _alignment(Node node) {
  final raw = node.args['textAlign']?.texto;
  return switch (raw) {
    'TextAlign.center' => TextAlign.center,
    'TextAlign.left' => TextAlign.left,
    'TextAlign.right' => TextAlign.right,
    'TextAlign.justify' => TextAlign.justify,
    _ => null,
  };
}

TextStyle _textStyle(BuildContext context, Node node) {
  final size = _number(node.args['fontSize']);
  final weight = _fontWeight(node.args['fontWeight']);
  final color = _color(node.args['color']);
  final bold = node.args['bold']?.texto == 'true';

  return TextStyle(
    fontSize: size,
    fontWeight: bold ? FontWeight.bold : weight,
    color: color ?? DefaultTextStyle.of(context).style.color,
  );
}

FontWeight? _fontWeight(Value? value) {
  final raw = value?.texto;
  if (raw == null) return null;
  if (raw.contains('bold')) return FontWeight.bold;
  if (raw.contains('w300')) return FontWeight.w300;
  if (raw.contains('w500')) return FontWeight.w500;
  if (raw.contains('w600')) return FontWeight.w600;
  if (raw.contains('w800')) return FontWeight.w800;
  return null;
}

EdgeInsets? _edgeInsets(Value? value) {
  if (value == null) return null;
  final raw = value.texto;

  final all = RegExp(r'EdgeInsets\.all\(([\d.]+)\)').firstMatch(raw);
  if (all != null) {
    final v = double.tryParse(all.group(1)!) ?? 0;
    return EdgeInsets.all(v);
  }

  final symmetric = RegExp(
    r'EdgeInsets\.symmetric\((?:horizontal:\s*([\d.]+))?,?\s*(?:vertical:\s*([\d.]+))?\)',
  ).firstMatch(raw);
  if (symmetric != null) {
    final h = double.tryParse(symmetric.group(1) ?? '') ?? 0;
    final v = double.tryParse(symmetric.group(2) ?? '') ?? 0;
    return EdgeInsets.symmetric(horizontal: h, vertical: v);
  }

  final only = RegExp(
    r'EdgeInsets\.only\((?:left:\s*([\d.]+))?,?\s*(?:top:\s*([\d.]+))?,?\s*(?:right:\s*([\d.]+))?,?\s*(?:bottom:\s*([\d.]+))?\)',
  ).firstMatch(raw);
  if (only != null) {
    return EdgeInsets.only(
      left: double.tryParse(only.group(1) ?? '') ?? 0,
      top: double.tryParse(only.group(2) ?? '') ?? 0,
      right: double.tryParse(only.group(3) ?? '') ?? 0,
      bottom: double.tryParse(only.group(4) ?? '') ?? 0,
    );
  }

  final number = double.tryParse(raw);
  if (number != null) return EdgeInsets.all(number);

  return null;
}

BoxDecoration? _decoration(Node node, BuildContext context) {
  // `decoration: BoxDecoration(...)` — o parser guarda como RawValue, então
  // lemos o texto. Simples e suficiente para o subconjunto.
  final raw = node.args['decoration']?.texto;
  final color = _color(node.args['color']);

  if (raw == null && color == null && node.args['borderRadius'] == null) {
    return null;
  }

  return BoxDecoration(
    color: color,
    borderRadius: _borderRadius(node.args['borderRadius']),
  );
}

BorderRadius? _borderRadius(Value? value) {
  if (value == null) return null;
  final raw = value.texto;
  final circular = RegExp(r'BorderRadius\.circular\(([\d.]+)\)').firstMatch(raw);
  if (circular != null) {
    return BorderRadius.circular(double.tryParse(circular.group(1)!) ?? 0);
  }
  final number = double.tryParse(raw);
  if (number != null) return BorderRadius.circular(number);
  return null;
}

Color? _color(Value? value) {
  if (value == null) return null;
  final raw = value.texto;

  const named = {
    'Colors.red': Colors.red,
    'Colors.blue': Colors.blue,
    'Colors.green': Colors.green,
    'Colors.orange': Colors.orange,
    'Colors.purple': Colors.purple,
    'Colors.grey': Colors.grey,
    'Colors.black': Colors.black,
    'Colors.white': Colors.white,
    'Colors.yellow': Colors.yellow,
    'Colors.pink': Colors.pink,
    'Colors.teal': Colors.teal,
    'Colors.indigo': Colors.indigo,
  };
  if (named.containsKey(raw)) return named[raw];

  final hex = RegExp(r'Color\(0x([0-9a-fA-F]{1,8})\)').firstMatch(raw);
  if (hex != null) {
    final v = int.tryParse(hex.group(1)!, radix: 16);
    if (v != null) return Color(v);
  }

  return null;
}

double? _number(Value? value) {
  if (value == null) return null;
  return double.tryParse(value.texto);
}

MainAxisAlignment _mainAxis(Node node) {
  return switch (node.args['mainAxisAlignment']?.texto) {
    'MainAxisAlignment.center' => MainAxisAlignment.center,
    'MainAxisAlignment.end' => MainAxisAlignment.end,
    'MainAxisAlignment.spaceBetween' => MainAxisAlignment.spaceBetween,
    'MainAxisAlignment.spaceAround' => MainAxisAlignment.spaceAround,
    'MainAxisAlignment.spaceEvenly' => MainAxisAlignment.spaceEvenly,
    _ => MainAxisAlignment.start,
  };
}

CrossAxisAlignment _crossAxis(Node node) {
  return switch (node.args['crossAxisAlignment']?.texto) {
    'CrossAxisAlignment.center' => CrossAxisAlignment.center,
    'CrossAxisAlignment.end' => CrossAxisAlignment.end,
    'CrossAxisAlignment.stretch' => CrossAxisAlignment.stretch,
    _ => CrossAxisAlignment.start,
  };
}

IconData _icon(Value? value) {
  final raw = value?.texto ?? '';
  if (raw.contains('favorite')) return Icons.favorite;
  if (raw.contains('star')) return Icons.star;
  if (raw.contains('home')) return Icons.home;
  if (raw.contains('person')) return Icons.person;
  if (raw.contains('warning')) return Icons.warning;
  return Icons.circle;
}
