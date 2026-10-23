import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

extension AdminContext on BuildContext {
  /// Verifica se o usuário atual é admin
  /// Retorna false e mostra snackbar se não for admin
  bool requireAdmin() {
    final authProvider = read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null || !user.isAdmin) {
      ScaffoldMessenger.of(this).showSnackBar(
        const SnackBar(
          content: Text('Acesso negado: apenas administradores'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  /// Verifica silenciosamente se o usuário é admin
  bool get isAdmin {
    final authProvider = read<AuthProvider>();
    return authProvider.currentUser?.isAdmin ?? false;
  }
}