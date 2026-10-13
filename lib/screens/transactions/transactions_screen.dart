import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../state/finance_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/recurrence_scope_dialog.dart';
import '../../widgets/section_card.dart';
import '../../widgets/transaction_tile.dart';
import 'transaction_editor_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({this.embedded = false, this.initialType, super.key});

  final bool embedded;
  final TransactionType? initialType;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _search = TextEditingController();
  TransactionType? _typeFilter;
  String? _categoryFilter;
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateHelpers.startOfMonth(DateTime.now());
    _typeFilter = widget.initialType;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final FinanceController finance = context.watch<FinanceController>();
    final SettingsController settings = context.watch<SettingsController>();
    final ThemeData theme = Theme.of(context);
    final String sym = settings.currencySymbol;

    final DateTime from = DateHelpers.startOfMonth(_month);
    final DateTime to = DateHelpers.endOfMonth(_month);

    final List<Transaction> list = finance.filtered(
      type: _typeFilter,
      categoryId: _categoryFilter,
      from: from,
      to: to,
      search: _search.text,
    );

    final double income = finance.sumFor(list, TransactionType.income);
    final double expense = finance.sumFor(list, TransactionType.expense);

    return AppScaffold(
      title: 'Extrato',
      body: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: <Widget>[
                  _monthSelector(theme, sym, income, expense),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Buscar por descrição...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <Widget>[
                        FilterChip(
                          label: const Text('Tudo'),
                          selected: _typeFilter == null,
                          onSelected: (_) =>
                              setState(() => _typeFilter = null),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Receitas'),
                          selected: _typeFilter == TransactionType.income,
                          onSelected: (_) => setState(
                              () => _typeFilter = TransactionType.income),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Despesas'),
                          selected: _typeFilter == TransactionType.expense,
                          onSelected: (_) => setState(
                              () => _typeFilter = TransactionType.expense),
                        ),
                        const SizedBox(width: 16),
                        _categoryDropdown(finance, theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          if (list.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Nada por aqui',
                message: 'Nenhum lançamento encontrado com esses filtros.',
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, widget.embedded ? 100 : 24),
              sliver: SliverList.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final Transaction t = list[index];
                  return TransactionTile(
                    transaction: t,
                    category: finance.categoryById(t.categoryId),
                    currencySymbol: sym,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => TransactionEditorScreen(existing: t),
                      ));
                    },
                    onLongPress: () => _confirmDelete(t),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const TransactionEditorScreen()));
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
      ),
    );
  }

  Widget _monthSelector(
      ThemeData theme, String sym, double income, double expense) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                Text(
                  DateHelpers.monthYear.format(_month),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        '+ ${Money.format(income, '', symbol: sym)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: const Color(0xFF06D6A0)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '- ${Money.format(expense, '', symbol: sym)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: const Color(0xFFEF476F)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _categoryDropdown(FinanceController finance, ThemeData theme) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String?>(
        value: _categoryFilter,
        hint: const Text('Categoria'),
        borderRadius: BorderRadius.circular(16),
        items: <DropdownMenuItem<String?>>[
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Todas as categorias'),
          ),
          ...finance.categories.map(
            (Category c) => DropdownMenuItem<String?>(
              value: c.id,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(c.icon, size: 16, color: c.color),
                  const SizedBox(width: 6),
                  Text(c.name),
                ],
              ),
            ),
          ),
        ],
        onChanged: (String? v) => setState(() => _categoryFilter = v),
      ),
    );
  }

  Future<void> _confirmDelete(Transaction t) async {
    final FinanceController finance = context.read<FinanceController>();
    if (t.recurrenceId != null) {
      final RecurrenceScope? scope = await showDeleteScopeDialog(context);
      if (scope == null) return;
      finance.deleteTransactionSeries(
        t.id,
        includeFuture: scope == RecurrenceScope.thisAndFuture,
      );
      return;
    }
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Excluir lançamento?'),
        content: const Text('Essa ação não pode ser desfeita.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true) {
      finance.deleteTransaction(t.id);
    }
  }
}
