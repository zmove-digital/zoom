import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/utils/id_generator.dart';
import '../../data/models/category.dart';
import '../../state/finance_controller.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/category_avatar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FinanceController finance = context.watch<FinanceController>();
    final ThemeData theme = Theme.of(context);

    final List<Category> income =
        finance.categories.where((Category c) => c.supportsIncome).toList();
    final List<Category> expense =
        finance.categories.where((Category c) => c.supportsExpense).toList();

    return AppScaffold(
      title: 'Categorias',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Nova'),
      ),
      body: finance.categories.isEmpty
          ? const EmptyState(
              icon: Icons.category_outlined,
              title: 'Sem categorias',
              message: 'Crie categorias para organizar seus lançamentos.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: <Widget>[
                if (income.isNotEmpty)
                  _group(context, theme, 'Entradas', income),
                if (expense.isNotEmpty)
                  _group(context, theme, 'Saídas', expense),
              ],
            ),
    );
  }

  Widget _group(BuildContext context, ThemeData theme, String label,
      List<Category> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        SectionCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: items
                .map(
                  (Category c) => ListTile(
                    leading: CategoryAvatar(category: c),
                    title: Text(c.name),
                    subtitle: Text(_kindLabel(c.kind)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openEditor(context, c),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  String _kindLabel(CategoryKind kind) {
    switch (kind) {
      case CategoryKind.income:
        return 'Somente entradas';
      case CategoryKind.expense:
        return 'Somente saídas';
      case CategoryKind.both:
        return 'Entradas e saídas';
    }
  }

  void _openEditor(BuildContext context, Category? category) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _CategoryEditor(category: category),
    );
  }
}

class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({this.category});

  final Category? category;

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  late TextEditingController _name;
  late CategoryKind _kind;
  late int _icon;
  late String _colorHex;

  @override
  void initState() {
    super.initState();
    final Category? c = widget.category;
    _name = TextEditingController(text: c?.name ?? '');
    _kind = c?.kind ?? CategoryKind.expense;
    _icon = c?.iconCodePoint ?? kCategoryIconChoices.first;
    _colorHex = c?.colorHex ?? kPaletteHex.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final FinanceController finance = context.read<FinanceController>();
    final String name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dê um nome para a categoria')),
      );
      return;
    }
    if (widget.category == null) {
      finance.addCategory(
        Category(
          id: newId(),
          name: name,
          kind: _kind,
          colorHex: _colorHex,
          iconCodePoint: _icon,
        ),
      );
    } else {
      finance.updateCategory(
        widget.category!.copyWith(
          name: name,
          kind: _kind,
          colorHex: _colorHex,
          iconCodePoint: _icon,
        ),
      );
    }
    Navigator.of(context).pop();
  }

  void _delete() {
    final FinanceController finance = context.read<FinanceController>();
    final int count =
        finance.transactionCountForCategory(widget.category!.id);
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Não é possível excluir: $count lançamento(s) usam esta categoria.'),
        ),
      );
      return;
    }
    finance.deleteCategory(widget.category!.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.category == null ? 'Nova categoria' : 'Editar categoria',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: colorFromHex(_colorHex).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(kIconsByCodePoint[_icon] ?? Icons.help_outline,
                      color: colorFromHex(_colorHex)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Tipo', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<CategoryKind>(
              segments: const <ButtonSegment<CategoryKind>>[
                ButtonSegment<CategoryKind>(
                    value: CategoryKind.expense, label: Text('Saída')),
                ButtonSegment<CategoryKind>(
                    value: CategoryKind.income, label: Text('Entrada')),
                ButtonSegment<CategoryKind>(
                    value: CategoryKind.both, label: Text('Ambas')),
              ],
              selected: <CategoryKind>{_kind},
              onSelectionChanged: (Set<CategoryKind> v) =>
                  setState(() => _kind = v.first),
            ),
            const SizedBox(height: 18),
            Text('Cor', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'A cor escolhida define a fatia desta categoria no gráfico de pizza em Relatórios.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: kPaletteHex.map((String hex) {
                final bool selected = hex == _colorHex;
                return GestureDetector(
                  onTap: () => setState(() => _colorHex = hex),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colorFromHex(hex),
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color: theme.colorScheme.onSurface, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Text('Ícone', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: kCategoryIconChoices.map((int code) {
                final bool selected = code == _icon;
                return GestureDetector(
                  onTap: () => setState(() => _icon = code),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? colorFromHex(_colorHex).withValues(alpha: 0.2)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? Border.all(color: colorFromHex(_colorHex), width: 2)
                          : null,
                    ),
                    child: Icon(
                      kIconsByCodePoint[code] ?? Icons.help_outline,
                      color: selected
                          ? colorFromHex(_colorHex)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                if (widget.category != null)
                  IconButton.filledTonal(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
