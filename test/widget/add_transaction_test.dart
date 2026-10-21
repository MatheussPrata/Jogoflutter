import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_quest/core/providers/transaction_provider.dart';
import 'package:flutter_quest/data/repositories_impl/transaction_repository_impl.dart';
import 'package:flutter_quest/domain/entities/transaction.dart';
import 'package:flutter_quest/presentation/widgets/add_transaction_fab.dart';
import 'package:flutter_quest/presentation/widgets/add_transaction_sheet.dart';

Widget _wrap(TransactionProvider provider, Widget child) {
  return ChangeNotifierProvider<TransactionProvider>.value(
    value: provider,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  late TransactionProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    provider = TransactionProvider(TransactionRepositoryImpl(prefs));
  });

  group('AddTransactionFab', () {
    testWidgets('renderiza botão redondo com ícone +', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(provider, AddTransactionFab(onPressed: () => tapped++)),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(AddTransactionFab),
          matching: find.byType(Material),
        ),
      );
      expect(material.shape, isA<CircleBorder>());

      await tester.tap(find.byIcon(Icons.add));
      expect(tapped, 1);
    });
  });

  group('AddTransactionSheet', () {
    testWidgets('salva uma despesa e atualiza o provider', (tester) async {
      await tester.pumpWidget(
        _wrap(
          provider,
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showAddTransactionSheet(context),
              child: const Text('abrir'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Nova transação'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Café');
      await tester.enterText(find.byType(TextFormField).at(1), '12,50');
      await tester.tap(find.text('Salvar transação'));
      await tester.pumpAndSettle();

      expect(provider.transactions.length, 1);
      expect(provider.transactions.single.description, 'Café');
      expect(provider.transactions.single.amount, 12.5);
      expect(provider.transactions.single.type, TransactionType.expense);
      expect(provider.balance, -12.5);
    });

    testWidgets('valida campos obrigatórios', (tester) async {
      await tester.pumpWidget(
        _wrap(
          provider,
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showAddTransactionSheet(context),
              child: const Text('abrir'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar transação'));
      await tester.pumpAndSettle();

      expect(find.text('Informe uma descrição'), findsOneWidget);
      expect(find.text('Informe o valor'), findsOneWidget);
      expect(provider.transactions, isEmpty);
    });

    testWidgets('receita soma no saldo', (tester) async {
      await provider.addTransaction(
        description: 'Salário',
        amount: 1000,
        type: TransactionType.income,
        category: 'Salário',
      );
      await provider.addTransaction(
        description: 'Mercado',
        amount: 250,
        type: TransactionType.expense,
        category: 'Alimentação',
      );

      expect(provider.totalIncome, 1000);
      expect(provider.totalExpense, 250);
      expect(provider.balance, 750);
    });
  });
}