import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/utils/formatters.dart';
import '../core/utils/id_generator.dart';
import '../data/models/account.dart';
import '../data/models/budget.dart';
import '../data/models/category.dart';
import '../data/models/goal.dart';
import '../data/models/transaction.dart';
import '../data/repositories/seed_data.dart';
import '../data/storage/local_database.dart';

class FinanceController extends ChangeNotifier {
  FinanceController(this._db) {
    transactions = _db
        .listOf(DbKeys.transactions)
        .map(Transaction.fromJson)
        .toList();
    categories =
        _db.listOf(DbKeys.categories).map(Category.fromJson).toList();
    budgets = _db.listOf(DbKeys.budgets).map(Budget.fromJson).toList();
    goals = _db.listOf(DbKeys.goals).map(Goal.fromJson).toList();
    accounts =
        _db.listOf(DbKeys.accounts).map(Account.fromJson).toList();

    if (categories.isEmpty) {
      categories = SeedData.defaultCategories();
      _persistCategories();
    }
    if (accounts.isEmpty) {
      accounts = SeedData.defaultAccounts();
      _persistAccounts();
    }

    _migrateLegacySettlement();
  }

  final LocalDatabase _db;
  late List<Transaction> transactions;
  late List<Category> categories;
  late List<Budget> budgets;
  late List<Goal> goals;
  late List<Account> accounts;

  String get currencySymbol =>
      kCurrencySymbols['BRL'] ?? 'R\$';

  Category? categoryById(String id) {
    for (final Category c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<Category> get incomeCategories =>
      categories.where((Category c) => c.supportsIncome).toList();
  List<Category> get expenseCategories =>
      categories.where((Category c) => c.supportsExpense).toList();

  List<Transaction> filtered({
    TransactionType? type,
    String? categoryId,
    DateTime? from,
    DateTime? to,
    String? search,
  }) {
    Iterable<Transaction> result = transactions;
    if (type != null) {
      result = result.where((Transaction t) => t.type == type);
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      result = result.where((Transaction t) => t.categoryId == categoryId);
    }
    if (from != null) {
      result = result.where((Transaction t) => !t.date.isBefore(from));
    }
    if (to != null) {
      final DateTime inclusive = DateTime(to.year, to.month, to.day, 23, 59, 59);
      result = result.where((Transaction t) => !t.date.isAfter(inclusive));
    }
    if (search != null && search.trim().isNotEmpty) {
      final String q = search.toLowerCase();
      result = result.where((Transaction t) =>
          t.description.toLowerCase().contains(q) ||
          t.notes.toLowerCase().contains(q));
    }
    final List<Transaction> list = result.toList()
      ..sort((Transaction a, Transaction b) => b.date.compareTo(a.date));
    return list;
  }

  double sumFor(
    Iterable<Transaction> list,
    TransactionType type,
  ) {
    double total = 0;
    for (final Transaction t in list) {
      if (t.type == type) total += t.amount;
    }
    return total;
  }

  double get goalsSaved {
    double total = 0;
    for (final Goal g in goals) {
      total += g.savedAmount;
    }
    return total;
  }

  /// Total guardado em metas dentro do período (para descontar no saldo do
  /// extrato, do mesmo jeito que [accountBalance] já desconta por conta).
  double goalContributionsBetween(DateTime from, DateTime to) =>
      Goal.contributionsBetween(goals, from, to);

  Account? accountById(String? id) {
    if (id == null) return null;
    for (final Account a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Saldo de uma conta: saldo inicial + lançamentos não futuros - valores
  /// guardados nas metas com origem nesta conta.
  double accountBalance(String id) {
    final Account? a = accountById(id);
    if (a == null) return 0;
    final DateTime now = DateTime.now();
    final DateTime endOfToday =
        DateTime(now.year, now.month, now.day, 23, 59, 59);
    double total = a.initialBalance;
    for (final Transaction t in transactions) {
      if (t.accountId != id) continue;
      if (t.date.isAfter(endOfToday)) continue;
      total += t.signedAmount;
    }
    for (final Goal g in goals) {
      for (final GoalContribution c in g.contributions) {
        if (c.accountId == id) total -= c.amount;
      }
    }
    return total;
  }

  /// Saldo total = soma dos saldos de todas as contas.
  double get totalBalance {
    double total = 0;
    for (final Account a in accounts) {
      total += accountBalance(a.id);
    }
    return total;
  }

  double get incomeThisMonth {
    final DateTime now = DateTime.now();
    return sumFor(
      transactions.where((Transaction t) => DateHelpers.isSameMonth(t.date, now)),
      TransactionType.income,
    );
  }

  double get expenseThisMonth {
    final DateTime now = DateTime.now();
    return sumFor(
      transactions.where((Transaction t) => DateHelpers.isSameMonth(t.date, now)),
      TransactionType.expense,
    );
  }

  static const int recurrenceHorizonMonths = 24;

  void addTransaction(Transaction t, {RecurrencePeriod? repeat}) {
    if (repeat == null) {
      transactions.add(t);
    } else {
      final String groupId = newId();
      t.recurrenceId = groupId;
      t.recurrence = repeat;
      transactions.add(t);
      transactions.addAll(
        _buildOccurrences(t, repeat, groupId, _recurrenceEnd(t.date)),
      );
    }
    _persistTransactions();
    notifyListeners();
  }

  void updateTransaction(Transaction t) {
    final int index = transactions.indexWhere((Transaction e) => e.id == t.id);
    if (index >= 0) {
      transactions[index] = t;
      _persistTransactions();
      notifyListeners();
    }
  }

  void deleteTransaction(String id) {
    transactions.removeWhere((Transaction t) => t.id == id);
    _persistTransactions();
    notifyListeners();
  }

  /// Efetiva um lançamento. Se a data ainda for futura, move para hoje;
  /// lançamentos vencidos mantêm a data original. Marca como efetivado.
  void settleTransaction(String id) {
    final int index = transactions.indexWhere((Transaction t) => t.id == id);
    if (index < 0) return;
    final DateTime now = DateTime.now();
    final Transaction t = transactions[index];
    if (t.isFuture) {
      t.date = DateTime(now.year, now.month, now.day, t.date.hour, t.date.minute);
    }
    t.isPaid = true;
    transactions[index] = t;
    _persistTransactions();
    notifyListeners();
  }

  /// Lançamentos vencidos (data passada e ainda não efetivados), do mais
  /// antigo para o mais recente.
  List<Transaction> get overdueTransactions {
    final List<Transaction> list =
        transactions.where((Transaction t) => t.isOverdue).toList()
          ..sort((Transaction a, Transaction b) =>
              a.date.compareTo(b.date));
    return list;
  }

  /// Migração de dados legados: antes a efetivação era automática pela data,
  /// então lançamentos antigos (`isPaid == null`) cuja data já chegou (hoje ou
  /// antes) permanecem efetivados — não viram "vencidos" por causa da mudança
  /// para efetivação manual. É idempotente: lançamentos novos sempre têm
  /// `isPaid` definido (true/false), então nunca são tocados.
  void _migrateLegacySettlement() {
    bool changed = false;
    for (final Transaction t in transactions) {
      if (t.isPaid == null && !t.isFuture) {
        t.isPaid = true;
        changed = true;
      }
    }
    if (changed) _persistTransactions();
  }

  void makeRecurringFrom(Transaction anchor, RecurrencePeriod repeat) {
    final int index =
        transactions.indexWhere((Transaction e) => e.id == anchor.id);
    if (index < 0) return;
    final String groupId = newId();
    anchor.recurrenceId = groupId;
    anchor.recurrence = repeat;
    transactions[index] = anchor;
    transactions.addAll(
      _buildOccurrences(anchor, repeat, groupId, _recurrenceEnd(anchor.date)),
    );
    _persistTransactions();
    notifyListeners();
  }

  void updateTransactionSeries(
    Transaction anchor, {
    required bool includeFuture,
    RecurrencePeriod? repeat,
  }) {
    final int index =
        transactions.indexWhere((Transaction e) => e.id == anchor.id);
    if (index < 0) return;
    final Transaction original = transactions[index];
    final String? groupId = original.recurrenceId;

    if (!includeFuture || groupId == null) {
      anchor.recurrenceId = original.recurrenceId;
      anchor.recurrence = original.recurrence;
      transactions[index] = anchor;
      _persistTransactions();
      notifyListeners();
      return;
    }

    transactions.removeWhere((Transaction e) =>
        e.recurrenceId == groupId &&
        e.id != anchor.id &&
        e.date.isAfter(anchor.date));

    if (repeat == null) {
      for (final Transaction e in transactions) {
        if (e.recurrenceId == groupId) {
          e.recurrenceId = null;
          e.recurrence = null;
        }
      }
      anchor.recurrenceId = null;
      anchor.recurrence = null;
    } else {
      anchor.recurrenceId = groupId;
      anchor.recurrence = repeat;
    }
    final int anchorIndex =
        transactions.indexWhere((Transaction e) => e.id == anchor.id);
    transactions[anchorIndex] = anchor;
    if (repeat != null) {
      transactions.addAll(
        _buildOccurrences(anchor, repeat, groupId, _recurrenceEnd(anchor.date)),
      );
    }
    _persistTransactions();
    notifyListeners();
  }

  void deleteTransactionSeries(String id, {required bool includeFuture}) {
    final int index = transactions.indexWhere((Transaction e) => e.id == id);
    if (index < 0) return;
    final Transaction t = transactions[index];
    if (!includeFuture || t.recurrenceId == null) {
      transactions.removeAt(index);
    } else {
      transactions.removeWhere((Transaction e) =>
          e.recurrenceId == t.recurrenceId && !e.date.isBefore(t.date));
    }
    _persistTransactions();
    notifyListeners();
  }

  DateTime _recurrenceEnd(DateTime start) =>
      addMonths(start, recurrenceHorizonMonths);

  List<Transaction> _buildOccurrences(
    Transaction base,
    RecurrencePeriod period,
    String groupId,
    DateTime end,
  ) {
    final List<Transaction> list = <Transaction>[];
    DateTime cursor = base.date;
    while (true) {
      cursor = period.next(cursor);
      if (cursor.isAfter(end)) break;
      list.add(Transaction(
        id: newId(),
        type: base.type,
        amount: base.amount,
        categoryId: base.categoryId,
        accountId: base.accountId,
        date: cursor,
        description: base.description,
        notes: base.notes,
        // Ocorrências futuras nascem pendentes: a efetivação é manual.
        isPaid: false,
        recurrenceId: groupId,
        recurrence: period,
      ));
    }
    return list;
  }

  void addCategory(Category c) {
    categories.add(c);
    _persistCategories();
    notifyListeners();
  }

  void updateCategory(Category c) {
    final int index = categories.indexWhere((Category e) => e.id == c.id);
    if (index >= 0) {
      categories[index] = c;
      _persistCategories();
      notifyListeners();
    }
  }

  void deleteCategory(String id) {
    categories.removeWhere((Category c) => c.id == id);
    budgets.removeWhere((Budget b) => b.categoryId == id);
    _persistCategories();
    _persistBudgets();
    notifyListeners();
  }

  int transactionCountForCategory(String categoryId) =>
      transactions.where((Transaction t) => t.categoryId == categoryId).length;

  double spentInCategory(String categoryId, DateTime month) {
    return sumFor(
      transactions.where((Transaction t) =>
          t.categoryId == categoryId &&
          t.type == TransactionType.expense &&
          DateHelpers.isSameMonth(t.date, month)),
      TransactionType.expense,
    );
  }

  static String monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  Budget? budgetFor(String categoryId, DateTime month) {
    final String key = monthKey(month);
    for (final Budget b in budgets) {
      if (b.categoryId == categoryId && b.monthKey == key) return b;
    }
    return null;
  }

  List<Budget> budgetsForMonth(DateTime month) {
    final String key = monthKey(month);
    return budgets.where((Budget b) => b.monthKey == key).toList();
  }

  void setBudget(String categoryId, double limit, DateTime month) {
    final String key = monthKey(month);
    final int index = budgets.indexWhere(
      (Budget b) => b.categoryId == categoryId && b.monthKey == key,
    );
    if (limit <= 0) {
      if (index >= 0) budgets.removeAt(index);
    } else if (index >= 0) {
      budgets[index] = budgets[index].copyWith(limit: limit);
    } else {
      budgets.add(
        Budget(id: newId(), categoryId: categoryId, limit: limit, monthKey: key),
      );
    }
    _persistBudgets();
    notifyListeners();
  }

  void addGoal(Goal g) {
    goals.add(g);
    _persistGoals();
    notifyListeners();
  }

  void updateGoal(Goal g) {
    final int index = goals.indexWhere((Goal e) => e.id == g.id);
    if (index >= 0) {
      goals[index] = g;
      _persistGoals();
      notifyListeners();
    }
  }

  void deleteGoal(String id) {
    goals.removeWhere((Goal g) => g.id == id);
    _persistGoals();
    notifyListeners();
  }

  void addAccount(Account a) {
    accounts.add(a);
    _persistAccounts();
    notifyListeners();
  }

  void updateAccount(Account a) {
    final int index = accounts.indexWhere((Account e) => e.id == a.id);
    if (index >= 0) {
      accounts[index] = a;
      _persistAccounts();
      notifyListeners();
    }
  }

  /// Remove uma conta movendo seus lançamentos e metas para a primeira conta
  /// restante. Não permite excluir a última conta.
  void deleteAccount(String id) {
    if (accounts.length <= 1) return;
    accounts.removeWhere((Account a) => a.id == id);
    final String fallback = accounts.first.id;
    for (final Transaction t in transactions) {
      if (t.accountId == id) t.accountId = fallback;
    }
    for (final Goal g in goals) {
      g.contributions = g.contributions
          .map((GoalContribution c) => c.accountId == id
              ? GoalContribution(
                  id: c.id,
                  accountId: fallback,
                  amount: c.amount,
                  date: c.date,
                )
              : c)
          .toList();
    }
    _persistTransactions();
    _persistAccounts();
    _persistGoals();
    notifyListeners();
  }

  void contributeToGoal(String id, String accountId, double amount) {
    final int index = goals.indexWhere((Goal g) => g.id == id);
    if (index < 0) return;
    final Goal g = goals[index];
    g.contributions = <GoalContribution>[
      ...g.contributions,
      GoalContribution(
        id: newId(),
        accountId: accountId,
        amount: Money.round2(amount),
      ),
    ];
    goals[index] = g;
    _persistGoals();
    notifyListeners();
  }

  Map<String, double> totalsByCategory(
    DateTime from,
    DateTime to, {
    TransactionType? type,
  }) {
    final DateTime inclusive = DateTime(to.year, to.month, to.day, 23, 59, 59);
    final Map<String, double> map = <String, double>{};
    for (final Transaction t in transactions) {
      if (type != null && t.type != type) continue;
      if (t.date.isBefore(from) || t.date.isAfter(inclusive)) continue;
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    return map;
  }

  Map<String, double> expenseByCategory(DateTime from, DateTime to) =>
      totalsByCategory(from, to, type: TransactionType.expense);

  List<MapEntry<DateTime, double>> monthlySeries(int months, {TransactionType? type}) {
    final DateTime now = DateTime.now();
    final List<MapEntry<DateTime, double>> series =
        <MapEntry<DateTime, double>>[];
    for (int i = months - 1; i >= 0; i--) {
      final DateTime month = DateTime(now.year, now.month - i);
      double total = 0;
      for (final Transaction t in transactions) {
        if (type != null && t.type != type) continue;
        if (DateHelpers.isSameMonth(t.date, month)) total += t.amount;
      }
      series.add(MapEntry<DateTime, double>(month, total));
    }
    return series;
  }

  void replaceEverything({
    required List<Transaction> transactions,
    required List<Category> categories,
    required List<Budget> budgets,
    required List<Goal> goals,
    required List<Account> accounts,
  }) {
    this.transactions = transactions;
    this.categories = categories;
    this.budgets = budgets;
    this.goals = goals;
    this.accounts = accounts;
    _persistTransactions();
    _persistCategories();
    _persistBudgets();
    _persistGoals();
    _persistAccounts();
    notifyListeners();
  }

  void _persistTransactions() =>
      _db.setList(DbKeys.transactions, transactions.map((Transaction e) => e.toJson()).toList());
  void _persistCategories() =>
      _db.setList(DbKeys.categories, categories.map((Category e) => e.toJson()).toList());
  void _persistBudgets() =>
      _db.setList(DbKeys.budgets, budgets.map((Budget e) => e.toJson()).toList());
  void _persistGoals() =>
      _db.setList(DbKeys.goals, goals.map((Goal e) => e.toJson()).toList());
  void _persistAccounts() =>
      _db.setList(DbKeys.accounts, accounts.map((Account e) => e.toJson()).toList());

  void reload() {
    transactions =
        _db.listOf(DbKeys.transactions).map(Transaction.fromJson).toList();
    categories =
        _db.listOf(DbKeys.categories).map(Category.fromJson).toList();
    budgets = _db.listOf(DbKeys.budgets).map(Budget.fromJson).toList();
    goals = _db.listOf(DbKeys.goals).map(Goal.fromJson).toList();
    accounts = _db.listOf(DbKeys.accounts).map(Account.fromJson).toList();
    if (categories.isEmpty) {
      categories = SeedData.defaultCategories();
      _persistCategories();
    }
    if (accounts.isEmpty) {
      accounts = SeedData.defaultAccounts();
      _persistAccounts();
    }
    _migrateLegacySettlement();
    notifyListeners();
  }
}
