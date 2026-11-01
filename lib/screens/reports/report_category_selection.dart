import '../../data/models/category.dart';

class ReportCategorySelection {
  static const String _allCategoriesId = '__all_report_categories__';

  final Set<String> selectedIds = <String>{};

  bool get allSelected => selectedIds.contains(_allCategoriesId);

  bool isSelected(String categoryId) =>
      allSelected || selectedIds.contains(categoryId);

  List<String> categoryIds(List<Category> categories) {
    if (allSelected) {
      return categories.map((Category category) => category.id).toList();
    }
    return selectedIds.toList();
  }

  void toggleAll(bool selected) {
    selectedIds
      ..clear()
      ..addAll(selected ? <String>[_allCategoriesId] : <String>[]);
  }

  void toggleCategory(
    String categoryId,
    bool selected,
    List<Category> categories,
  ) {
    final Set<String> allIds =
        categories.map((Category category) => category.id).toSet();
    if (allSelected) {
      if (selected) return;
      selectedIds
        ..clear()
        ..addAll(allIds)
        ..remove(categoryId);
      return;
    }

    if (selected) {
      selectedIds.add(categoryId);
      if (selectedIds.containsAll(allIds)) {
        toggleAll(true);
      }
    } else {
      selectedIds.remove(categoryId);
    }
  }
}
