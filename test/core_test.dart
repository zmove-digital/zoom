import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoom/core/utils/formatters.dart';
import 'package:zoom/data/models/account.dart';
import 'package:zoom/data/models/agenda_entry.dart';
import 'package:zoom/data/models/category.dart';
import 'package:zoom/data/models/goal.dart';
import 'package:zoom/data/models/transaction.dart';
import 'package:zoom/services/backup_crypto.dart';

void main() {
  group('Money', () {
    test('parse aceita vírgula e ponto', () {
      expect(Money.parse('1.234,56'), 1234.56);
      expect(Money.parse('12,5'), 12.5);
      expect(Money.parse('9.99'), 9.99);
    });

    test('round2 arredonda centavos', () {
      expect(Money.round2(10.005), 10.01);
      expect(Money.round2(9.999), 10.0);
    });
  });

  group('DateHelpers', () {
    test('isSameMonth funciona', () {
      expect(
        DateHelpers.isSameMonth(DateTime(2026, 5, 1), DateTime(2026, 5, 31)),
        isTrue,
      );
      expect(
        DateHelpers.isSameMonth(DateTime(2026, 5, 31), DateTime(2026, 6, 1)),
        isFalse,
      );
    });
  });

  group('Transaction', () {
    test('json roundtrip preserva dados', () {
      final Transaction tx = Transaction(
        id: 'abc',
        type: TransactionType.income,
        amount: 150.5,
        categoryId: 'cat1',
        date: DateTime(2026, 5, 20, 10, 30),
        description: 'Freela',
        notes: 'ok',
      );
      final Transaction restored = Transaction.fromJson(tx.toJson());
      expect(restored.id, 'abc');
      expect(restored.type, TransactionType.income);
      expect(restored.amount, 150.5);
      expect(restored.description, 'Freela');
      expect(restored.signedAmount, 150.5);
    });

    test('despesa tem valor negativo assinado', () {
      final Transaction tx = Transaction(
        id: 'x',
        type: TransactionType.expense,
        amount: 12,
        categoryId: 'c',
        date: DateTime(2026),
      );
      expect(tx.signedAmount, -12);
    });
  });

  group('Transaction efetivação', () {
    DateTime dayFrom(int days) =>
        DateHelpers.startOfDay(DateTime.now()).add(Duration(days: days));

    test('não efetiva sozinho: data passada e isPaid false fica vencido', () {
      final Transaction t = Transaction(
        id: 't1',
        type: TransactionType.expense,
        amount: 10,
        categoryId: 'c',
        date: dayFrom(-1),
        isPaid: false,
      );
      expect(t.isSettled, isFalse);
      expect(t.isPending, isTrue);
      expect(t.isPastDue, isTrue);
      expect(t.isOverdue, isTrue);
    });

    test('efetivado quando isPaid é true', () {
      final Transaction t = Transaction(
        id: 't2',
        type: TransactionType.expense,
        amount: 10,
        categoryId: 'c',
        date: dayFrom(-1),
        isPaid: true,
      );
      expect(t.isSettled, isTrue);
      expect(t.isOverdue, isFalse);
    });

    test('data futura nunca é efetivada nem vencida', () {
      final Transaction t = Transaction(
        id: 't3',
        type: TransactionType.income,
        amount: 10,
        categoryId: 'c',
        date: dayFrom(2),
        isPaid: true,
      );
      expect(t.isSettled, isFalse);
      expect(t.isPastDue, isFalse);
      expect(t.isOverdue, isFalse);
    });

    test('legado (isPaid nulo) com data passada aparece vencido', () {
      final Transaction t = Transaction(
        id: 't4',
        type: TransactionType.expense,
        amount: 10,
        categoryId: 'c',
        date: dayFrom(-3),
      );
      expect(t.isPaid, isNull);
      expect(t.isSettled, isFalse);
      expect(t.isOverdue, isTrue);
    });
  });

  group('Recurrence', () {
    test('addMonths faz clamp no fim do mês e vira o ano', () {
      expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(addMonths(DateTime(2026, 12, 15), 1), DateTime(2027, 1, 15));
      expect(addMonths(DateTime(2026, 3, 31), 1), DateTime(2026, 4, 30));
    });

    test('next respeita o período', () {
      final DateTime d = DateTime(2026, 5, 10);
      expect(RecurrencePeriod.weekly.next(d), DateTime(2026, 5, 17));
      expect(RecurrencePeriod.biweekly.next(d), DateTime(2026, 5, 24));
      expect(RecurrencePeriod.monthly.next(d), DateTime(2026, 6, 10));
    });

    test('json roundtrip preserva a recorrência', () {
      final Transaction tx = Transaction(
        id: 'r1',
        type: TransactionType.expense,
        amount: 30,
        categoryId: 'c',
        date: DateTime(2026, 5, 10),
        recurrenceId: 'grp',
        recurrence: RecurrencePeriod.monthly,
      );
      final Transaction restored = Transaction.fromJson(tx.toJson());
      expect(restored.recurrenceId, 'grp');
      expect(restored.recurrence, RecurrencePeriod.monthly);
      expect(restored.isRecurring, isTrue);
    });
  });

  group('Category', () {
    test('kind parsing tolera valores desconhecidos', () {
      expect(categoryKindFromName('income'), CategoryKind.income);
      expect(categoryKindFromName('nada'), CategoryKind.both);
    });

    test('supportsIncome e supportsExpense respeitam kind', () {
      final Category income = Category(
        id: 'a',
        name: 'Salario',
        kind: CategoryKind.income,
        colorHex: '06D6A0',
        iconCodePoint: 0xe263,
      );
      expect(income.supportsIncome, isTrue);
      expect(income.supportsExpense, isFalse);

      final Color color = colorFromHex('06D6A0');
      expect(color, isA<Color>());
      expect(colorToHex(color), '06D6A0');
    });
  });

  group('Account', () {
    test('json roundtrip preserva tipo e saldo inicial', () {
      final Account a = Account(
        id: 'acc1',
        name: 'Nubank',
        type: AccountType.checking,
        initialBalance: 250.75,
      );
      final Account restored = Account.fromJson(a.toJson());
      expect(restored.id, 'acc1');
      expect(restored.name, 'Nubank');
      expect(restored.type, AccountType.checking);
      expect(restored.initialBalance, 250.75);
      expect(restored.colorHex, a.colorHex);
    });

    test('tipo desconhecido vira outros', () {
      expect(accountTypeFromName('nada'), AccountType.other);
    });
  });

  group('Goal', () {
    test('savedAmount soma as contribuicoes', () {
      final Goal g = Goal(
        id: 'g1',
        name: 'Viagem',
        targetAmount: 1000,
        contributions: <GoalContribution>[
          GoalContribution(id: 'c1', accountId: 'a1', amount: 100),
          GoalContribution(id: 'c2', accountId: 'a2', amount: 150),
        ],
      );
      expect(g.savedAmount, 250);
      expect(g.progress, 0.25);

      final Goal restored = Goal.fromJson(g.toJson());
      expect(restored.savedAmount, 250);
      expect(restored.contributions.length, 2);
      expect(restored.contributions.first.accountId, 'a1');
    });
  });

  group('AgendaEntry', () {    test('json roundtrip preserva mood e tags', () {
      final AgendaEntry entry = AgendaEntry(
        id: 'e1',
        date: DateTime(2026, 5, 1),
        title: 'Bom dia',
        content: 'Texto livre',
        mood: Mood.great,
        tags: <String>['dieta', 'foco'],
      );
      final AgendaEntry restored = AgendaEntry.fromJson(entry.toJson());
      expect(restored.mood, Mood.great);
      expect(restored.tags, <String>['dieta', 'foco']);
      expect(restored.content, 'Texto livre');
    });
  });

  group('BackupCrypto', () {
    final Map<String, dynamic> payload = <String, dynamic>{
      'app': 'ZOOM',
      'data': <String, dynamic>{
        'transactions': <dynamic>[
          <String, dynamic>{'id': 't1', 'amount': 10.5},
        ],
      },
    };

    test('encrypt gera envelope e não expõe o conteúdo', () {
      final Map<String, dynamic> env = BackupCrypto.encrypt(payload, '1234');
      expect(BackupCrypto.isEncrypted(env), isTrue);
      expect(env.containsKey('salt'), isTrue);
      expect(env.containsKey('iv'), isTrue);
      expect(env['cipher'], 'AES-256-GCM');
      expect(env.toString().contains('10.5'), isFalse);
    });

    test('decrypt com o PIN correto recupera os dados', () {
      final Map<String, dynamic> env = BackupCrypto.encrypt(payload, '1234');
      final Map<String, dynamic>? decoded = BackupCrypto.decrypt(env, '1234');
      expect(decoded, isNotNull);
      expect(decoded!['data'], payload['data']);
    });

    test('decrypt com PIN errado retorna null', () {
      final Map<String, dynamic> env = BackupCrypto.encrypt(payload, '1234');
      expect(BackupCrypto.decrypt(env, '9999'), isNull);
    });

    test('salt aleatório muda o texto cifrado', () {
      final Map<String, dynamic> a = BackupCrypto.encrypt(payload, '1234');
      final Map<String, dynamic> b = BackupCrypto.encrypt(payload, '1234');
      expect(a['data'], isNot(b['data']));
    });
  });
}