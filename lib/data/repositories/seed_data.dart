import '../models/account.dart';
import '../models/category.dart';
import '../../core/utils/id_generator.dart';

class _CategorySpec {
  const _CategorySpec(this.name, this.kind, this.color, this.icon);

  final String name;
  final CategoryKind kind;
  final String color;
  final int icon;
}

class _AccountSpec {
  const _AccountSpec(this.name, this.type, this.color);

  final String name;
  final AccountType type;
  final String color;
}

/// Categorias e contas que vêm com o app.
///
/// As mesmas listas são usadas para instalações novas e para atualizar os
/// padrões de quem já usa o app: os ids são preservados nas renomeações, então
/// nenhuma transação perde a categoria.
class SeedData {
  static const List<_CategorySpec> _categorySeeds = <_CategorySpec>[
    _CategorySpec('Salário', CategoryKind.income, '06D6A0', 0xe263),
    _CategorySpec('Empréstimos', CategoryKind.income, '4ECDC4', 0xe0b2),
    _CategorySpec('Comissões', CategoryKind.income, '43AA8B', 0xe553),
    _CategorySpec('Supermercado', CategoryKind.expense, 'FF6B6B', 0xe59c),
    _CategorySpec('Transporte', CategoryKind.expense, '457B9D', 0xe1d5),
    _CategorySpec('Lazer', CategoryKind.expense, 'A06CD5', 0xe7f4),
    _CategorySpec('Assinaturas', CategoryKind.expense, 'F8961E', 0xe501),
    _CategorySpec('Estudos', CategoryKind.expense, '577590', 0xe265),
    _CategorySpec('Roupas', CategoryKind.expense, 'F78FB3', 0xe8b6),
    _CategorySpec('Luz', CategoryKind.expense, 'FFD166', 0xe37c),
    _CategorySpec('Água', CategoryKind.expense, '118AB2', 0xf05a2),
    _CategorySpec('Telefone', CategoryKind.expense, '4ECDC4', 0xe5c6),
    _CategorySpec('Internet', CategoryKind.expense, '457B9D', 0xe6e7),
    _CategorySpec('Pets', CategoryKind.expense, 'F78FB3', 0xe4a1),
    _CategorySpec('Combustível', CategoryKind.expense, 'F8961E', 0xe394),
    _CategorySpec('Oficina Mecânica', CategoryKind.expense, '577590', 0xe13d),
    _CategorySpec('Saúde', CategoryKind.expense, 'EF476F', 0xe396),
    _CategorySpec('Empréstimos', CategoryKind.expense, '43AA8B', 0xe0b2),
    _CategorySpec('Aluguel', CategoryKind.expense, 'A06CD5', 0xe318),
    _CategorySpec('Bobagens', CategoryKind.expense, 'FFD166', 0xe2f2),
    _CategorySpec('Restaurante', CategoryKind.expense, 'EF476F', 0xe532),
    _CategorySpec('Shopee', CategoryKind.expense, 'F78FB3', 0xe59a),
  ];

  static const List<_AccountSpec> _accountSeeds = <_AccountSpec>[
    _AccountSpec('Carteira', AccountType.cash, '06D6A0'),
    _AccountSpec('NuBank', AccountType.checking, 'A06CD5'),
    _AccountSpec('Mercado Pago', AccountType.checking, '118AB2'),
  ];

  /// Nomes antigos que devem ser renomeados em vez de duplicados.
  static const Map<String, _CategorySpec> _categoryRenames =
      <String, _CategorySpec>{
    'salario': _CategorySpec('Salário', CategoryKind.income, '06D6A0', 0xe263),
    'freela': _CategorySpec(
      'Empréstimos',
      CategoryKind.income,
      '4ECDC4',
      0xe0b2,
    ),
    'mesalanches': _CategorySpec(
      'Supermercado',
      CategoryKind.expense,
      'FF6B6B',
      0xe59c,
    ),
    'rolelazer': _CategorySpec(
      'Lazer',
      CategoryKind.expense,
      'A06CD5',
      0xe7f4,
    ),
    'contas': _CategorySpec('Luz', CategoryKind.expense, 'FFD166', 0xe37c),
    'outros': _CategorySpec(
      'Comissões',
      CategoryKind.income,
      '43AA8B',
      0xe553,
    ),
  };

  static List<Account> defaultAccounts() {
    return _accountSeeds
        .map(
          (spec) => Account(
            id: newId(),
            name: spec.name,
            type: spec.type,
            colorHex: spec.color,
          ),
        )
        .toList();
  }

  static List<Category> defaultCategories() {
    return _categorySeeds
        .map(
          (spec) => Category(
            id: newId(),
            name: spec.name,
            kind: spec.kind,
            colorHex: spec.color,
            iconCodePoint: spec.icon,
            isDefault: true,
          ),
        )
        .toList();
  }

  /// Aplica o padrão atual sobre listas já carregadas do disco.
  /// Retorna `true` quando algo foi alterado.
  static bool standardizeDefaults({
    required List<Category> categories,
    required List<Account> accounts,
  }) {
    bool changed = false;

    for (final Category category in categories) {
      if (!category.isDefault) continue;
      final _CategorySpec? spec = _categoryRenames[_normalize(category.name)];
      if (spec == null) continue;
      category
        ..name = spec.name
        ..kind = spec.kind
        ..colorHex = spec.color
        ..iconCodePoint = spec.icon;
      changed = true;
    }

    for (final _CategorySpec spec in _categorySeeds) {
      final String name = _normalize(spec.name);
      final bool exists = categories.any(
        (Category c) => _normalize(c.name) == name && c.kind == spec.kind,
      );
      if (exists) continue;
      categories.add(
        Category(
          id: newId(),
          name: spec.name,
          kind: spec.kind,
          colorHex: spec.color,
          iconCodePoint: spec.icon,
          isDefault: true,
        ),
      );
      changed = true;
    }

    for (final _AccountSpec spec in _accountSeeds) {
      final String name = _normalize(spec.name);
      if (accounts.any((Account a) => _normalize(a.name) == name)) continue;
      accounts.add(
        Account(
          id: newId(),
          name: spec.name,
          type: spec.type,
          colorHex: spec.color,
        ),
      );
      changed = true;
    }

    return changed;
  }

  /// Remove acentos, espaços e pontuação para comparar nomes de forma estável.
  static String _normalize(String value) {
    String text = value.toLowerCase();
    for (final MapEntry<String, String> entry in const <String, String>{
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    }.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    return text.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
