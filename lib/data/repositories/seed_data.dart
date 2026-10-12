import '../models/category.dart';
import '../../core/utils/id_generator.dart';

class SeedData {
  static List<Category> defaultCategories() {
    return <Category>[
      Category(
        id: newId(),
        name: 'Salario',
        kind: CategoryKind.income,
        colorHex: '06D6A0',
        iconCodePoint: 0xe263,
        isDefault: true,
      ),
      Category(
        id: newId(),
        name: 'Freela',
        kind: CategoryKind.income,
        colorHex: '4ECDC4',
        iconCodePoint: 0xe53d,
        isDefault: true,
      ),
      Category(
        id: newId(),
        name: 'Mesa / Lanches',
        kind: CategoryKind.expense,
        colorHex: 'FF6B6B',
        iconCodePoint: 0xe56b,
        isDefault: true,
      ),
      Category(
        id: newId(),
        name: 'Transporte',
        kind: CategoryKind.expense,
        colorHex: '457B9D',
        iconCodePoint: 0xe530,
        isDefault: true,
      ),
      Category(
        id: newId(),
        name: 'Rolê / Lazer',
        kind: CategoryKind.expense,
        colorHex: 'A06CD5',
        iconCodePoint: 0xe7f4,
        isDefault: true,
      ),
      Category(
        id: newId(),
        name: 'Assinaturas',
        kind: CategoryKind.expense,
        colorHex: 'F8961E',
        iconCodePoint: 0xe501,
        isDefault: true,
      ),
      Category(
        id: newId(),
        name: 'Estudos',
        kind: CategoryKind.expense,
        colorHex: '577590',
        iconCodePoint: 0xe265,
        isDefault: true,
      ),
      Category(
        id: newId(),
        name: 'Roupas',
        kind: CategoryKind.expense,
        colorHex: 'F78FB3',
        iconCodePoint: 0xe8b6,
        isDefault: true,
      ),
      Category(
        id: newId(),
        name: 'Contas',
        kind: CategoryKind.expense,
        colorHex: 'EF476F',
        iconCodePoint: 0xe8a1,
        isDefault: true,
      ),
      Category(
        id: newId(),
        name: 'Outros',
        kind: CategoryKind.both,
        colorHex: '118AB2',
        iconCodePoint: 0xe5d3,
        isDefault: true,
      ),
    ];
  }
}
