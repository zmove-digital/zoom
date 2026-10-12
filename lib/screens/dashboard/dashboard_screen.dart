import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/budget.dart';
import '../../data/models/category.dart';
import '../../data/models/goal.dart';
import '../../data/models/transaction.dart';
import '../../state/agenda_controller.dart';
import '../../state/finance_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/category_avatar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/hero_card.dart';
import '../../widgets/section_card.dart';
import '../../widgets/transaction_tile.dart';
import '../categories/categories_screen.dart';
import '../goals/goals_screen.dart';
import '../budgets/budgets_screen.dart';
import '../reminders/reminders_screen.dart';
import '../transactions/transaction_editor_screen.dart';
import '../transactions/transactions_screen.dart';
import '../agenda/agenda_editor_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final FinanceController finance = context.watch<FinanceController>();
    final SettingsController settings = context.watch<SettingsController>();
    final AgendaController agenda = context.watch<AgendaController>();
    final ThemeData theme = Theme.of(context);

    final String sym = settings.currencySymbol;
    final double balance = finance.totalBalance;
    final double income = finance.incomeThisMonth;
    final double expense = finance.expenseThisMonth;
    final String name = settings.settings.userName;

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('${_greeting()},',
                        style: theme.textTheme.bodyMedium),
                    Text(
                      name.isEmpty ? 'jovem' : name,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                  child: Icon(Icons.savings_rounded,
                      color: theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 20),
            HeroCard(
              balance: balance,
              income: income,
              expense: expense,
              currencySymbol: sym,
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: StatCard(
                    label: 'Entradas (mês)',
                    value: Money.compact(income, sym),
                    icon: Icons.arrow_upward_rounded,
                    color: const Color(0xFF06D6A0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Saídas (mês)',
                    value: Money.compact(expense, sym),
                    icon: Icons.arrow_downward_rounded,
                    color: const Color(0xFFEF476F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _quickActions(context, finance),
            const SizedBox(height: 20),
            if (finance.budgetsForMonth(DateTime.now()).isNotEmpty) ...<Widget>[
              _budgetSection(context, finance, sym),
              const SizedBox(height: 20),
            ],
            if (finance.goals.isNotEmpty) ...<Widget>[
              _goalsSection(context, finance, sym, theme),
              const SizedBox(height: 20),
            ],
            _agendaShortcut(context, agenda, theme),
            const SizedBox(height: 20),
            _recentTransactions(context, finance, sym, theme),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context, FinanceController finance) {
    final List<_QuickAction> actions = <_QuickAction>[
      _QuickAction('Categorias', Icons.category_outlined, () {
        Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const CategoriesScreen()));
      }),
      _QuickAction('Orçamentos', Icons.donut_large_outlined, () {
        Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const BudgetsScreen()));
      }),
      _QuickAction('Metas', Icons.flag_outlined, () {
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const GoalsScreen()));
      }),
      _QuickAction('Lembretes', Icons.alarm_outlined, () {
        Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const RemindersScreen()));
      }),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: actions
          .map(
            (_QuickAction a) => ActionChip(
              avatar: Icon(a.icon, size: 18),
              label: Text(a.label),
              onPressed: a.onTap,
            ),
          )
          .toList(),
    );
  }

  Widget _budgetSection(
      BuildContext context, FinanceController finance, String sym) {
    final ThemeData theme = Theme.of(context);
    final List<Budget> budgets = finance.budgetsForMonth(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Orçamentos do mês',
            style:
                theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        SectionCard(
          child: Column(
            children: budgets.map((Budget b) {
              final Category? c = finance.categoryById(b.categoryId);
              final double spent = finance.spentInCategory(b.categoryId, DateTime.now());
              final double ratio =
                  (b.limit <= 0 ? 0.0 : spent / b.limit).clamp(0.0, 1.5).toDouble();
              final bool over = spent > b.limit;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        CategoryAvatar(category: c, size: 30),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(c?.name ?? 'Categoria',
                              style: theme.textTheme.bodyMedium),
                        ),
                        Text(
                          '${Money.compact(spent, sym)} / ${Money.compact(b.limit, sym)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: over
                                ? theme.colorScheme.error
                                : theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0, 1).toDouble(),
                        minHeight: 8,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        color: over
                            ? theme.colorScheme.error
                            : (c?.color ?? theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _goalsSection(BuildContext context, FinanceController finance,
      String sym, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Suas metas',
            style:
                theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: finance.goals.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (BuildContext context, int index) {
              final Goal g = finance.goals[index];
              return SizedBox(
                width: 200,
                child: SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(Icons.flag_rounded, color: g.color, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(g.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text('${(g.progress * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: g.progress.toDouble(),
                          minHeight: 8,
                          color: g.color,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${Money.compact(g.savedAmount, sym)} de ${Money.compact(g.targetAmount, sym)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _agendaShortcut(
      BuildContext context, AgendaController agenda, ThemeData theme) {
    final String? lastContent =
        agenda.entries.isEmpty ? null : agenda.sorted().first.title;
    return SectionCard(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const AgendaEditorScreen()));
      },
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            child: Icon(Icons.edit_note_rounded,
                color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Seu diário',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(
                  agenda.thisMonthCount == 0
                      ? 'Escreva como foi seu dia'
                      : '${agenda.thisMonthCount} registros este mês • sequência de ${agenda.streak} dias',
                  style: theme.textTheme.bodySmall,
                ),
                if (lastContent != null && lastContent.isNotEmpty)
                  Text('Último: $lastContent',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  Widget _recentTransactions(BuildContext context, FinanceController finance,
      String sym, ThemeData theme) {
    final List<Transaction> recent = finance.filtered().take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('Últimos lançamentos',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const TransactionsScreen(embedded: true)));
              },
              child: const Text('Ver tudo'),
            ),
          ],
        ),
        if (recent.isEmpty)
          SectionCard(
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Nenhum lançamento ainda',
              message: 'Toque no + para registrar sua primeira receita ou despesa.',
              action: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const TransactionEditorScreen()));
                },
                icon: const Icon(Icons.add),
                label: const Text('Adicionar lançamento'),
              ),
            ),
          )
        else
          SectionCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: recent
                  .map(
                    (Transaction t) => TransactionTile(
                      transaction: t,
                      category: finance.categoryById(t.categoryId),
                      currencySymbol: sym,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => TransactionEditorScreen(existing: t),
                        ));
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _QuickAction {
  _QuickAction(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}
