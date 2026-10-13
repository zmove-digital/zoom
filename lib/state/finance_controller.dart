import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/utils/formatters.dart';
import '../core/utils/id_generator.dart';
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

    if (categories.isEmpty) {
      categories = SeedData.defaultCategories();
      _persistCategories();
    }
  }

  final LocalDatabase _db;
  late List<Transaction> transactions;
  late List<Category> categories;
  late List<Budget> budgets;
  late List<Goal> goals;

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

  double get totalBalance {
    final DateTime now = DateTime.now();
    final DateTime endOfToday =
        DateTime(now.year, now.month, now.day, 23, 59, 59);
    double total = 0;
    for (final Transaction t in transactions) {
      if (t.date.isAfter(endOfToday)) continue;
      total += t.signedAmount;
    }
    return total - goalsSaved;
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
        date: cursor,
        description: base.description,
        notes: base.notes,
        isPaid: base.isPaid,
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

  void contributeToGoal(String id, double amount) {
    final int index = goals.indexWhere((Goal g) => g.id == id);
    if (index >= 0) {
      final Goal g = goals[index];
      goals[index] = g.copyWith(
        savedAmount: Money.round2(g.savedAmount + amount),
      );
      _persistGoals();
      notifyListeners();
    }
  }

  Map<String, double> expenseByCategory(DateTime from, DateTime to) {
    final DateTime inclusive = DateTime(to.year, to.month, to.day, 23, 59, 59);
    final Map<String, double> map = <String, double>{};
    for (final Transaction t in transactions) {
      if (t.type != TransactionType.expense) continue;
      if (t.date.isBefore(from) || t.date.isAfter(inclusive)) continue;
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    return map;
  }

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
  }) {
    this.transactions = transactions;
    this.categories = categories;
    this.budgets = budgets;
    this.goals = goals;
    _persistTransactions();
    _persistCategories();
    _persistBudgets();
    _persistGoals();
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

  void reload() {
    transactions =
        _db.listOf(DbKeys.transactions).map(Transaction.fromJson).toList();
    categories =
        _db.listOf(DbKeys.categories).map(Category.fromJson).toList();
    budgets = _db.listOf(DbKeys.budgets).map(Budget.fromJson).toList();
    goals = _db.listOf(DbKeys.goals).map(Goal.fromJson).toList();
    if (categories.isEmpty) {
      categories = SeedData.defaultCategories();
      _persistCategories();
    }
    notifyListeners();
  }
}
