import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
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
import '../agenda/diary_report_screen.dart';

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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
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
              currencySymbol: sym,
              hidden: settings.settings.hideBalance,
              onToggleHidden: () => settings
                  .setHideBalance(!settings.settings.hideBalance),
            ),
            const SizedBox(height: 16),
            _primaryAction(context),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: StatCard(
                    label: 'Entradas',
                    value: Money.format(income, '', symbol: sym),
                    icon: Icons.arrow_upward_rounded,
                    color: const Color(0xFF06D6A0),
                    hidden: settings.settings.hideBalance,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => const TransactionsScreen(
                            initialType: TransactionType.income),
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Saídas',
                    value: Money.format(expense, '', symbol: sym),
                    icon: Icons.arrow_downward_rounded,
                    color: const Color(0xFFEF476F),
                    hidden: settings.settings.hideBalance,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => const TransactionsScreen(
                            initialType: TransactionType.expense),
                      ));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _quickActions(context),
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

  Widget _primaryAction(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const Color onHero = Color(0xFFFFFFFF);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const TransactionEditorScreen()));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: kHeroGradient,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: kHeroGradient.last.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0x33FFFFFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: onHero, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Novo lançamento',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: onHero,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: onHero),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _navCard(
                context,
                label: 'Categorias',
                icon: Icons.category_outlined,
                color: const Color(0xFF4361EE),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const CategoriesScreen()));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _navCard(
                context,
                label: 'Orçamentos',
                icon: Icons.donut_large_outlined,
                color: const Color(0xFFF8961E),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const BudgetsScreen()));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _navCard(
                context,
                label: 'Metas',
                icon: Icons.flag_outlined,
                color: const Color(0xFF9B5DE5),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const GoalsScreen()));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _navCard(
                context,
                label: 'Lembretes',
                icon: Icons.alarm_outlined,
                color: const Color(0xFF00BBF9),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const RemindersScreen()));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _navCard(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final ThemeData theme = Theme.of(context);
    return SectionCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: withOpacity(color, 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
                          '${Money.format(spent, '', symbol: sym)} / ${Money.format(b.limit, '', symbol: sym)}',
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
                        '${Money.format(g.savedAmount, '', symbol: sym)} de ${Money.format(g.targetAmount, '', symbol: sym)}',
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
            child: Icon(Icons.emoji_emotions_rounded,
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
          IconButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const DiaryReportScreen()));
            },
            tooltip: 'Relatório do diário',
            icon: const Icon(Icons.star_half_rounded),
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
