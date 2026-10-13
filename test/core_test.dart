import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoom/core/utils/formatters.dart';
import 'package:zoom/data/models/agenda_entry.dart';
import 'package:zoom/data/models/category.dart';
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

  group('AgendaEntry', () {
    test('json roundtrip preserva mood e tags', () {
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