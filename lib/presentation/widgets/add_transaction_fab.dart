import 'package:flutter/material.dart';

/// Botão flutuante redondo central com ícone de "+" para adicionar transação.
class AddTransactionFab extends StatelessWidget {
  final VoidCallback onPressed;

  const AddTransactionFab({super.key, required this.onPressed});

  static const double size = 64;
  static const double verticalLift = 18;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: scheme.primary,
        shape: const CircleBorder(),
        elevation: 8,
        shadowColor: scheme.primary.withAlpha(128),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(
            Icons.add,
            size: 34,
            color: scheme.onPrimary,
            semanticLabel: 'Adicionar transação',
          ),
        ),
      ),
    );
  }
}