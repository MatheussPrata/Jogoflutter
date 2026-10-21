import 'package:flutter/material.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/repositories/repositories.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _repository;

  List<Transaction> _transactions = <Transaction>[];
  bool _isLoading = false;
  String? _error;

  TransactionProvider(this._repository);

  List<Transaction> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _transactions.isEmpty;

  double get totalIncome => _transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _transactions = await _repository.getAll();
      _isLoading = false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> addTransaction({
    required String description,
    required double amount,
    required TransactionType type,
    required String category,
  }) async {
    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: description,
      amount: amount,
      type: type,
      category: category,
      date: DateTime.now(),
    );
    await _repository.add(transaction);
    _transactions = await _repository.getAll();
    notifyListeners();
  }

  Future<void> removeTransaction(String id) async {
    await _repository.remove(id);
    _transactions = await _repository.getAll();
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _repository.clear();
    _transactions = <Transaction>[];
    notifyListeners();
  }
}
