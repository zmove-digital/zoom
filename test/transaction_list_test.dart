import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoom/core/constants.dart';
import 'package:zoom/core/utils/formatters.dart';
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
