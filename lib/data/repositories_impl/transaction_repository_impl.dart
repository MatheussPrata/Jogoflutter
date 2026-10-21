import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/repositories/repositories.dart';

/// Persiste transações em SharedPreferences (local, sem backend).
class TransactionRepositoryImpl implements TransactionRepository {
  static const String _key = 'flutter_quest_transactions';

  final SharedPreferences _prefs;

  TransactionRepositoryImpl(this._prefs);

  @override
  Future<List<Transaction>> getAll() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <Transaction>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final items = list
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
      items.sort((a, b) => b.date.compareTo(a.date));
      return items;
    } on FormatException {
      return <Transaction>[];
    }
  }

  Future<void> _save(List<Transaction> items) async {
    final raw = jsonEncode(items.map((t) => t.toJson()).toList());
    await _prefs.setString(_key, raw);
  }

  @override
  Future<void> add(Transaction transaction) async {
    final items = await getAll();
    items.add(transaction);
    await _save(items);
  }

  @override
  Future<void> remove(String id) async {
    final items = await getAll();
    items.removeWhere((t) => t.id == id);
    await _save(items);
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
