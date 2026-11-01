import 'package:flutter_test/flutter_test.dart';
import 'package:zoom/core/constants.dart';
import 'package:zoom/data/models/account.dart';
import 'package:zoom/data/models/goal.dart';
import 'package:zoom/data/models/transaction.dart';
import 'package:zoom/data/storage/local_database.dart';
import 'package:zoom/state/finance_controller.dart';

void main() {
  FinanceController controllerWith({List<Goal>? goals}) {
    final LocalDatabase database = LocalDatabase.inMemory();
    database.setList(DbKeys.accounts, <Map<String, dynamic>>[
      Account(
        id: 'account-1',
        name: 'Conta principal',
        type: AccountType.checking,
        initialBalance: 1000,
      ).toJson(),
    ]);
    database.setList(
      DbKeys.goals,
      (goals ?? <Goal>[]).map((Goal goal) => goal.toJson()).toList(),
    );
    return FinanceController(database);
  }

  test(
    'legacy contributions migrate once and stay in sync with the ledger',
    () {
      final Goal goal = Goal(
        id: 'goal-1',
        name: 'Viagem',
        targetAmount: 2000,
        contributions: <GoalContribution>[
          GoalContribution(
            id: 'contribution-1',
            accountId: 'account-1',
            amount: 125,
          ),
        ],
      );
      final FinanceController finance = controllerWith(goals: <Goal>[goal]);
      final Transaction legacyTransaction = finance.transactions.single;

      expect(legacyTransaction.isGoalContribution, isTrue);
      expect(legacyTransaction.categoryId, goalContributionCategoryId);
      expect(finance.categoryById(legacyTransaction.categoryId)?.name, 'Meta');
      expect(
        finance.filtered(categoryId: goalContributionCategoryId),
        hasLength(1),
      );
      expect(finance.accountBalance('account-1'), 875);
      expect(finance.goalsSaved, 125);

      finance.reload();
      expect(finance.transactions, hasLength(1));

      expect(
        finance.updateGoalContribution(legacyTransaction.copyWith(amount: 80)),
        isTrue,
      );
      expect(finance.goals.single.savedAmount, 80);
      expect(finance.transactions.single.amount, 80);
      expect(finance.accountBalance('account-1'), 920);
      expect(finance.expenseThisMonth, 80);
      final DateTime now = DateTime.now();
      expect(
        finance.expenseByCategory(
          DateTime(now.year, now.month),
          DateTime(now.year, now.month + 1, 0),
        )[goalContributionCategoryId],
        80,
      );

      finance.deleteTransaction(legacyTransaction.id);
      expect(finance.transactions, isEmpty);
      expect(finance.goals.single.savedAmount, 0);
      expect(finance.accountBalance('account-1'), 1000);
    },
  );

  test('new contributions create an editable Meta transaction', () {
    final FinanceController finance = controllerWith(
      goals: <Goal>[Goal(id: 'goal-2', name: 'Reserva', targetAmount: 500)],
    );

    finance.contributeToGoal('goal-2', 'account-1', 42.50);

    final Transaction transaction = finance.transactions.single;
    expect(transaction.isGoalContribution, isTrue);
    expect(transaction.type, TransactionType.expense);
    expect(transaction.categoryId, goalContributionCategoryId);
    expect(transaction.description, 'Reserva');
    expect(transaction.amount, 42.5);
    expect(finance.goals.single.savedAmount, 42.5);
    expect(finance.accountBalance('account-1'), 957.5);

    finance.deleteGoal('goal-2');
    expect(finance.transactions, isEmpty);
    expect(finance.accountBalance('account-1'), 1000);
  });
}
