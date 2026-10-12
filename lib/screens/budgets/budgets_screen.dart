import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/category.dart';
import '../../state/finance_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/category_avatar.dart';
import '../../widgets/section_card.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateHelpers.startOfMonth(DateTime.now());
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  Future<void> _editLimit(Category category, double current, String sym) async {
    final TextEditingController controller = TextEditingController(
      text: current <= 0 ? '' : current.toStringAsFixed(2).replaceAll('.', ','),
    );
    final double? value = await showDialog<double>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Limite para ${category.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Limite mensal',
            prefixText: '$sym ',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 0.0),
            child: const Text('Remover'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, Money.parse(controller.text)),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (value != null && mounted) {
      context.read<FinanceController>().setBudget(category.id, value, _month);
    }
  }

  @override
  Widget build(BuildContext context) {
    final FinanceController finance = context.watch<FinanceController>();
    final SettingsController settings = context.watch<SettingsController>();
    final ThemeData theme = Theme.of(context);
    final String sym = settings.currencySymbol;
    final List<Category> cats = finance.expenseCategories;

    double totalLimit = 0;
    double totalSpent = 0;
    for (final Category c in cats) {
      final double limit = finance.budgetFor(c.id, _month)?.limit ?? 0;
      final double spent = finance.spentInCategory(c.id, _month);
      totalLimit += limit;
      totalSpent += spent;
    }

    return AppScaffold(
      title: 'Orçamentos',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          SectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      DateHelpers.monthYear.format(_month),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Resumo',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('Gasto: ${Money.compact(totalSpent, sym)}'),
                    Text('Limite: ${Money.compact(totalLimit, sym)}'),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: totalLimit <= 0
                        ? 0
                        : (totalSpent / totalLimit).clamp(0, 1).toDouble(),
                    minHeight: 10,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: totalSpent > totalLimit
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...cats.map((Category c) {
            final double limit = finance.budgetFor(c.id, _month)?.limit ?? 0;
            final double spent = finance.spentInCategory(c.id, _month);
            final double ratio =
                (limit <= 0 ? 0.0 : spent / limit).clamp(0.0, 1.5).toDouble();
            final bool over = limit > 0 && spent > limit;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SectionCard(
                onTap: () => _editLimit(c, limit, sym),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        CategoryAvatar(category: c, size: 36),
                        const SizedBox(width: 12),
                        Expanded(child: Text(c.name)),
                        Text(
                          limit <= 0
                              ? 'Definir limite'
                              : '${Money.compact(spent, sym)} / ${Money.compact(limit, sym)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: over
                                ? theme.colorScheme.error
                                : theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    if (limit > 0) ...<Widget>[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: ratio.clamp(0, 1).toDouble(),
                          minHeight: 8,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          color: over ? theme.colorScheme.error : c.color,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
