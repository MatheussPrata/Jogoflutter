import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_quest/data/repositories_impl/transaction_repository_impl.dart';
import 'package:flutter_quest/domain/entities/transaction.dart';

Transaction _tx({
  required String id,
  required double amount,
  required TransactionType type,
  required DateTime date,
  String description = 'item',
}) {
  return Transaction(
    id: id,
    description: description,
    amount: amount,
    type: type,
    category: 'Outros',
    date: date,
  );
}

void main() {
  late TransactionRepositoryImpl repo;

  Future<TransactionRepositoryImpl> makeRepo([Map<String, Object>? initial]) async {
    SharedPreferences.setMockInitialValues(initial ?? <String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return TransactionRepositoryImpl(prefs);
  }

  setUp(() async {
    repo = await makeRepo();
  });

  test('começa vazio', () async {
    expect(await repo.getAll(), isEmpty);
  });

  test('adiciona e persiste transações', () async {
    final now = DateTime(2026, 10, 21);
    await repo.add(_tx(id: '1', amount: 100, type: TransactionType.income, date: now));
    await repo.add(_tx(id: '2', amount: 25.5, type: TransactionType.expense, date: now));

    final all = await repo.getAll();
    expect(all.length, 2);
  });

  test('ordena por data decrescente', () async {
    await repo.add(_tx(id: 'old', amount: 1, type: TransactionType.income, date: DateTime(2026, 1, 1)));
    await repo.add(_tx(id: 'new', amount: 2, type: TransactionType.income, date: DateTime(2026, 6, 1)));

    final all = await repo.getAll();
    expect(all.first.id, 'new');
    expect(all.last.id, 'old');
  });

  test('remove por id', () async {
    await repo.add(_tx(id: '1', amount: 10, type: TransactionType.income, date: DateTime(2026, 1, 1)));
    await repo.add(_tx(id: '2', amount: 20, type: TransactionType.income, date: DateTime(2026, 1, 2)));

    await repo.remove('1');

    final all = await repo.getAll();
    expect(all.length, 1);
    expect(all.single.id, '2');
  });

  test('clear apaga tudo', () async {
    await repo.add(_tx(id: '1', amount: 10, type: TransactionType.income, date: DateTime(2026, 1, 1)));
    await repo.clear();
    expect(await repo.getAll(), isEmpty);
  });

  test('JSON corrompido retorna lista vazia', () async {
    final brokenRepo = await makeRepo(<String, Object>{
      'flutter_quest_transactions': '{oops',
    });
    expect(await brokenRepo.getAll(), isEmpty);
  });

  test('Transaction serializa e desserializa', () {
    final t = _tx(
      id: '1',
      amount: 42.5,
      type: TransactionType.expense,
      date: DateTime.parse('2026-10-21T10:00:00.000Z'),
      description: 'Café',
    );

    final restored = Transaction.fromJson(
      jsonDecode(jsonEncode(t.toJson())) as Map<String, dynamic>,
    );

    expect(restored.id, t.id);
    expect(restored.description, 'Café');
    expect(restored.amount, 42.5);
    expect(restored.type, TransactionType.expense);
    expect(restored.signedAmount, -42.5);
  });
}