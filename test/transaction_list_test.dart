import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoom/core/constants.dart';
import 'package:zoom/core/utils/formatters.dart';
import 'package:zoom/data/models/category.dart';
import 'package:zoom/data/models/transaction.dart';
import 'package:zoom/data/storage/local_database.dart';
import 'package:zoom/state/finance_controller.dart';
import 'package:zoom/widgets/transaction_tile.dart';

Transaction _tx(
  String id,
  DateTime date, {
  required DateTime createdAt,
  String description = 'Lançamento',
}) {
  return Transaction(
    id: id,
    type: TransactionType.expense,
    amount: 10,
    categoryId: 'cat',
    date: date,
    description: description,
    createdAt: createdAt,
  );
}

void main() {
  test('extrato ordena por data e desempata pela criação', () {
    final LocalDatabase db = LocalDatabase.inMemory();
    db.setList(
      DbKeys.transactions,
      <Map<String, dynamic>>[
        _tx(
          'antigo',
          DateTime(2026, 11, 10),
          createdAt: DateTime(2026, 11, 1, 10),
        ).toJson(),
        _tx(
          'novo',
          DateTime(2026, 11, 25),
          createdAt: DateTime(2026, 11, 2, 10),
        ).toJson(),
        _tx(
          'recente-mesma-data',
          DateTime(2026, 11, 10),
          createdAt: DateTime(2026, 11, 3, 10),
        ).toJson(),
        _tx(
          'meio',
          DateTime(2026, 11, 21),
          createdAt: DateTime(2026, 11, 4, 10),
        ).toJson(),
      ],
    );
    final FinanceController finance = FinanceController(db);

    expect(
      finance.filtered().map((t) => t.id).toList(),
      <String>['novo', 'meio', 'recente-mesma-data', 'antigo'],
    );
  });

  test('busca encontra lançamentos pela descrição ou pelo nome da categoria', () {
    final LocalDatabase db = LocalDatabase.inMemory();
    db.setList(
      DbKeys.categories,
      <Map<String, dynamic>>[
        Category(
          id: 'mercado',
          name: 'Supermercado',
          kind: CategoryKind.expense,
          colorHex: 'FF6B6B',
          iconCodePoint: 0xe59c,
        ).toJson(),
        Category(
          id: 'farmacia',
          name: 'Farmácia',
          kind: CategoryKind.expense,
          colorHex: 'EF476F',
          iconCodePoint: 0xe396,
        ).toJson(),
      ],
    );
    db.setList(
      DbKeys.transactions,
      <Map<String, dynamic>>[
        Transaction(
          id: 't1',
          type: TransactionType.expense,
          amount: 10,
          categoryId: 'mercado',
          date: DateTime(2026, 11, 21),
          description: 'Compra',
        ).toJson(),
        Transaction(
          id: 't2',
          type: TransactionType.expense,
          amount: 20,
          categoryId: 'farmacia',
          date: DateTime(2026, 11, 20),
          description: 'Receita',
        ).toJson(),
      ],
    );
    final FinanceController finance = FinanceController(db);

    expect(
      finance.filtered(search: 'super').map((t) => t.id).toList(),
      <String>['t1'],
    );
    expect(
      finance.filtered(search: 'farm').map((t) => t.id).toList(),
      <String>['t2'],
    );
    expect(
      finance.filtered(search: 'compra').map((t) => t.id).toList(),
      <String>['t1'],
    );
    expect(finance.filtered(search: 'inexistente'), isEmpty);
  });

  testWidgets('item do extrato mostra a data mesmo com descrição longa', (
    WidgetTester tester,
  ) async {
    final DateTime date = DateTime(2026, 11, 25);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionTile(
            transaction: _tx(
              't',
              date,
              createdAt: date,
              description:
                  'Descrição muito longa que normalmente cortaria a data no fim da linha',
            ),
            category: null,
            currencySymbol: r'R$',
          ),
        ),
      ),
    );

    expect(find.text(DateHelpers.full.format(date)), findsOneWidget);
  });
}
