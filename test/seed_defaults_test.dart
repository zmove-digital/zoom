import 'package:flutter_test/flutter_test.dart';
import 'package:zoom/core/constants.dart';
import 'package:zoom/data/models/account.dart';
import 'package:zoom/data/models/category.dart';
import 'package:zoom/data/repositories/seed_data.dart';
import 'package:zoom/data/storage/local_database.dart';
import 'package:zoom/state/finance_controller.dart';

void main() {
  test('categorias e contas padrão usam os nomes padronizados', () {
    final categories = SeedData.defaultCategories();
    final accounts = SeedData.defaultAccounts();

    expect(
      categories.map((c) => c.name),
      containsAll(<String>[
        'Salário',
        'Empréstimos',
        'Comissões',
        'Supermercado',
        'Lazer',
        'Luz',
        'Água',
        'Telefone',
        'Internet',
        'Pets',
        'Combustível',
        'Oficina Mecânica',
        'Saúde',
        'Aluguel',
        'Bobagens',
        'Restaurante',
        'Shopee',
      ]),
    );
    expect(
      categories.where((c) => c.name == 'Empréstimos').map((c) => c.kind),
      containsAll(<CategoryKind>[CategoryKind.income, CategoryKind.expense]),
    );
    expect(
      categories.where((c) => c.name == 'Outros' || c.name == 'Freela'),
      isEmpty,
    );
    expect(categories.every((c) => c.isDefault), isTrue);
    expect(
      accounts.map((a) => a.name),
      containsAll(<String>['Carteira', 'NuBank', 'Mercado Pago']),
    );
  });

  test('migra padrões antigos preservando ids e itens do usuário', () {
    final LocalDatabase db = LocalDatabase.inMemory();
    db.setList(
      DbKeys.categories,
      <Map<String, dynamic>>[
        Category(
          id: 'c-salario',
          name: 'Salario',
          kind: CategoryKind.income,
          colorHex: '06D6A0',
          iconCodePoint: 0xe263,
          isDefault: true,
        ).toJson(),
        Category(
          id: 'c-freela',
          name: 'Freela',
          kind: CategoryKind.income,
          colorHex: '4ECDC4',
          iconCodePoint: 0xe53d,
          isDefault: true,
        ).toJson(),
        Category(
          id: 'c-mesa',
          name: 'Mesa / Lanches',
          kind: CategoryKind.expense,
          colorHex: 'FF6B6B',
          iconCodePoint: 0xe56b,
          isDefault: true,
        ).toJson(),
        Category(
          id: 'c-role',
          name: 'Rolê / Lazer',
          kind: CategoryKind.expense,
          colorHex: 'A06CD5',
          iconCodePoint: 0xe7f4,
          isDefault: true,
        ).toJson(),
        Category(
          id: 'c-contas',
          name: 'Contas',
          kind: CategoryKind.expense,
          colorHex: 'EF476F',
          iconCodePoint: 0xe8a1,
          isDefault: true,
        ).toJson(),
        Category(
          id: 'c-outros',
          name: 'Outros',
          kind: CategoryKind.both,
          colorHex: '118AB2',
          iconCodePoint: 0xe5d3,
          isDefault: true,
        ).toJson(),
        Category(
          id: 'c-custom',
          name: 'Viagem',
          kind: CategoryKind.expense,
          colorHex: '06D6A0',
          iconCodePoint: 0xe59c,
        ).toJson(),
      ],
    );
    db.setList(
      DbKeys.accounts,
      <Map<String, dynamic>>[
        Account(
          id: 'a-carteira',
          name: 'Carteira',
          type: AccountType.cash,
        ).toJson(),
        Account(
          id: 'a-custom',
          name: 'Conta do mercado',
          type: AccountType.checking,
        ).toJson(),
      ],
    );

    final FinanceController finance = FinanceController(db);

    Category byId(String id) =>
        finance.categories.firstWhere((c) => c.id == id);

    expect(byId('c-salario').name, 'Salário');
    expect(byId('c-freela').name, 'Empréstimos');
    expect(byId('c-freela').kind, CategoryKind.income);
    expect(byId('c-mesa').name, 'Supermercado');
    expect(byId('c-role').name, 'Lazer');
    expect(byId('c-contas').name, 'Luz');
    expect(byId('c-outros').name, 'Comissões');
    expect(byId('c-outros').kind, CategoryKind.income);
    expect(byId('c-custom').name, 'Viagem');

    expect(
      finance.accounts.map((a) => a.name),
      containsAll(<String>[
        'Carteira',
        'Conta do mercado',
        'NuBank',
        'Mercado Pago',
      ]),
    );

    // A migração é idempotente: rodar de novo não duplica nada.
    final int total = finance.categories.length;
    finance.reload();
    expect(finance.categories, hasLength(total));
  });
}
