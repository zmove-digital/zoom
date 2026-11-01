import 'package:flutter_test/flutter_test.dart';
import 'package:zoom/data/models/category.dart';
import 'package:zoom/screens/reports/report_category_selection.dart';

void main() {
  final List<Category> categories = <Category>[
    Category(
      id: 'food',
      name: 'Alimentação',
      kind: CategoryKind.expense,
      colorHex: 'FF0000',
      iconCodePoint: 1,
    ),
    Category(
      id: 'salary',
      name: 'Salário',
      kind: CategoryKind.income,
      colorHex: '00FF00',
      iconCodePoint: 2,
    ),
  ];

  test('selecting Todas includes every current and future report category', () {
    final ReportCategorySelection selection =
        ReportCategorySelection()..toggleAll(true);

    expect(selection.allSelected, isTrue);
    expect(selection.isSelected('food'), isTrue);
    expect(selection.categoryIds(categories), <String>['food', 'salary']);
  });

  test('unchecking one category from Todas keeps the other categories', () {
    final ReportCategorySelection selection =
        ReportCategorySelection()
          ..toggleAll(true)
          ..toggleCategory('food', false, categories);

    expect(selection.allSelected, isFalse);
    expect(selection.isSelected('food'), isFalse);
    expect(selection.categoryIds(categories), <String>['salary']);

    selection.toggleCategory('food', true, categories);
    expect(selection.allSelected, isTrue);
    expect(selection.categoryIds(categories), <String>['food', 'salary']);
  });

  test('clearing Todas leaves the report without selected categories', () {
    final ReportCategorySelection selection =
        ReportCategorySelection()
          ..toggleAll(true)
          ..toggleAll(false);

    expect(selection.allSelected, isFalse);
    expect(selection.categoryIds(categories), isEmpty);
  });
}
