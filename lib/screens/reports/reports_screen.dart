import 'dart:convert';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../services/pdf_report_service.dart';
import '../../state/finance_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/section_card.dart';

enum _Period { month, last30, year, all, custom }

enum _PieMode { expense, income, both }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _Period _period = _Period.month;
  _PieMode _pieMode = _PieMode.expense;
  DateTime? _customFrom;
  DateTime? _customTo;
  _Period _catPeriod = _Period.month;
  DateTime? _catFrom;
  DateTime? _catTo;
  final Set<String> _selectedCategories = <String>{};

  _PieMode get _nextPieMode =>
      _PieMode.values[(_pieMode.index + 1) % _PieMode.values.length];

  (DateTime, DateTime) _range() =>
      _rangeFor(_period, _customFrom, _customTo);

  (DateTime, DateTime) _catRange() =>
      _rangeFor(_catPeriod, _catFrom, _catTo);

  (DateTime, DateTime) _rangeFor(
      _Period period, DateTime? customFrom, DateTime? customTo) {
    final DateTime now = DateTime.now();
    switch (period) {
      case _Period.month:
        return (DateHelpers.startOfMonth(now), DateHelpers.endOfMonth(now));
      case _Period.last30:
        return (
          DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 29)),
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case _Period.year:
        return (DateTime(now.year), DateTime(now.year, 12, 31, 23, 59, 59));
      case _Period.all:
        return (DateTime(2000), DateTime(2100));
      case _Period.custom:
        final DateTime from = customFrom ?? DateHelpers.startOfMonth(now);
        final DateTime to = customTo ?? DateHelpers.endOfMonth(now);
        return (from, DateTime(to.year, to.month, to.day, 23, 59, 59));
    }
  }

  String _periodLabel() => _labelFor(_period, _customFrom, _customTo);

  String _catPeriodLabel() => _labelFor(_catPeriod, _catFrom, _catTo);

  String _labelFor(
      _Period period, DateTime? customFrom, DateTime? customTo) {
    switch (period) {
      case _Period.month:
        return 'Este mês';
      case _Period.last30:
        return 'Últimos 30 dias';
      case _Period.year:
        return 'Este ano';
      case _Period.all:
        return 'Tudo';
      case _Period.custom:
        if (customFrom != null && customTo != null) {
          return '${DateHelpers.full.format(customFrom)} a ${DateHelpers.full.format(customTo)}';
        }
        return 'Período personalizado';
    }
  }

  Future<void> _pickCustomRange() async {
    final DateTimeRange? picked = await _pickRange(_customFrom, _customTo);
    if (picked != null) {
      setState(() {
        _customFrom = picked.start;
        _customTo = picked.end;
        _period = _Period.custom;
      });
    }
  }

  Future<void> _pickCatCustomRange() async {
    final DateTimeRange? picked = await _pickRange(_catFrom, _catTo);
    if (picked != null) {
      setState(() {
        _catFrom = picked.start;
        _catTo = picked.end;
        _catPeriod = _Period.custom;
      });
    }
  }

  Future<DateTimeRange?> _pickRange(DateTime? from, DateTime? to) {
    final DateTime now = DateTime.now();
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: (from != null && to != null)
          ? DateTimeRange(start: from, end: to)
          : DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: DateTime(now.year, now.month, now.day),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FinanceController finance = context.watch<FinanceController>();
    final SettingsController settings = context.watch<SettingsController>();
    final ThemeData theme = Theme.of(context);
    final String sym = settings.currencySymbol;

    final (DateTime from, DateTime to) = _range();
    final List<Transaction> list =
        finance.filtered(from: from, to: to);
    final double income = finance.sumFor(list, TransactionType.income);
    final double expense = finance.sumFor(list, TransactionType.expense);
    final double balance = income - expense;

    final TransactionType? pieType = switch (_pieMode) {
      _PieMode.expense => TransactionType.expense,
      _PieMode.income => TransactionType.income,
      _PieMode.both => null,
    };
    final Map<String, double> byCategory =
        finance.totalsByCategory(from, to, type: pieType);
    final double pieTotal =
        byCategory.values.fold(0.0, (double a, double b) => a + b);
    final String pieTitle = switch (_pieMode) {
      _PieMode.expense => 'Despesas por categoria',
      _PieMode.income => 'Receitas por categoria',
      _PieMode.both => 'Receitas e despesas por categoria',
    };

    final List<MapEntry<String, double>> sortedCats =
        byCategory.entries.toList()
          ..sort((MapEntry<String, double> a, MapEntry<String, double> b) =>
              b.value.compareTo(a.value));

    return AppScaffold(
      title: 'Relatórios',
      actions: <Widget>[
        IconButton(
          onPressed: list.isEmpty
              ? null
              : () => _export(list, income, expense,
                  finance.expenseByCategory(from, to), sym, finance),
          icon: const Icon(Icons.ios_share),
          tooltip: 'Exportar',
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _Period.values.map((_Period p) {
                final bool selected = _period == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_periodLabelFor(p)),
                    selected: selected,
                    onSelected: (_) {
                      if (p == _Period.custom) {
                        _pickCustomRange();
                      } else {
                        setState(() => _period = p);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: StatCard(
                  label: 'Entradas',
                  value: Money.format(income, '', symbol: sym),
                  icon: Icons.arrow_upward,
                  color: const Color(0xFF06D6A0),
                  caption: _periodLabel(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Saídas',
                  value: Money.format(expense, '', symbol: sym),
                  icon: Icons.arrow_downward,
                  color: const Color(0xFFEF476F),
                  caption: _periodLabel(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Saldo do período',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(
                  Money.format(balance, '', symbol: sym),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: balance >= 0
                        ? const Color(0xFF06D6A0)
                        : theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(pieTitle,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Text('toque para alternar',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            ],
          ),
          const SizedBox(height: 12),
          if (sortedCats.isEmpty)
            SectionCard(
              child: SizedBox(
                height: 120,
                child: Center(
                  child: Text('Sem dados no período',
                      style: theme.textTheme.bodyMedium),
                ),
              ),
            )
          else
            SectionCard(
              child: SizedBox(
                height: 240,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _pieMode = _nextPieMode),
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 42,
                            sections:
                                sortedCats.map((MapEntry<String, double> e) {
                              final Category? c = finance.categoryById(e.key);
                              final double pct = pieTotal <= 0
                                  ? 0
                                  : (e.value / pieTotal) * 100;
                              return PieChartSectionData(
                                value: e.value,
                                color: c?.color ?? theme.colorScheme.primary,
                                title: pct >= 8
                                    ? '${pct.toStringAsFixed(0)}%'
                                    : '',
                                radius: 52,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListView(
                        children: sortedCats.take(8).map(
                          (MapEntry<String, double> e) {
                            final Category? c = finance.categoryById(e.key);
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: c?.color ??
                                          theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      c?.name ?? '—',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                  Text(
                                    Money.format(e.value, '', symbol: sym),
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            );
                          },
                        ).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          _categoryReportSection(finance, theme, sym),
          const SizedBox(height: 20),
          Text('Últimos 6 meses',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SectionCard(
            child: SizedBox(
              height: 220,
              child: _barChart(finance, theme, sym),
            ),
          ),
        ],
      ),
    );
  }

  String _periodLabelFor(_Period p) {
    switch (p) {
      case _Period.month:
        return 'Mês';
      case _Period.last30:
        return '30 dias';
      case _Period.year:
        return 'Ano';
      case _Period.all:
        return 'Tudo';
      case _Period.custom:
        return 'Período';
    }
  }

  Widget _categoryReportSection(
      FinanceController finance, ThemeData theme, String sym) {
    final (DateTime from, DateTime to) = _catRange();
    final List<_ReportGroup> groups = _reportGroups(finance, from, to);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Relatório por categoria',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          'Escolha uma ou mais categorias para ver os lançamentos e exportar em PDF no período selecionado.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 10),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _Period.values.map((_Period p) {
                    final bool selected = _catPeriod == p;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_periodLabelFor(p)),
                        selected: selected,
                        onSelected: (_) {
                          if (p == _Period.custom) {
                            _pickCatCustomRange();
                          } else {
                            setState(() => _catPeriod = p);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 4),
              Text(_catPeriodLabel(),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
              const Divider(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.checklist_rtl),
                title: Text(_selectedCategories.isEmpty
                    ? 'Escolher categorias'
                    : 'Categorias selecionadas'),
                subtitle: Text(_selectedCategories.isEmpty
                    ? 'Nenhuma categoria escolhida'
                    : '${_selectedCategories.length} selecionada(s)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _pickCategories(finance),
              ),
              if (_selectedCategories.isNotEmpty) ...<Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _selectedCategories
                      .map((String id) => finance.categoryById(id))
                      .whereType<Category>()
                      .map((Category c) => Chip(
                            avatar: Icon(c.icon, size: 16, color: c.color),
                            label: Text(c.name),
                            onDeleted: () => setState(
                                () => _selectedCategories.remove(c.id)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                if (groups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                        'Sem lançamentos dessas categorias no período.',
                        style: theme.textTheme.bodySmall),
                  )
                else
                  ...groups.map(
                      (_ReportGroup g) => _groupTile(g, theme, sym)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: groups.isEmpty
                        ? null
                        : () => _exportPdf(finance, from, to, sym),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Exportar PDF'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<_ReportGroup> _reportGroups(
      FinanceController finance, DateTime from, DateTime to) {
    final List<_ReportGroup> groups = <_ReportGroup>[];
    for (final String id in _selectedCategories) {
      final Category? c = finance.categoryById(id);
      if (c == null) continue;
      final List<Transaction> items =
          finance.filtered(categoryId: id, from: from, to: to);
      if (items.isEmpty) continue;
      double total = 0;
      for (final Transaction t in items) {
        total += t.signedAmount;
      }
      groups.add(_ReportGroup(c, items, total));
    }
    groups.sort((_ReportGroup a, _ReportGroup b) => a.category.name
        .toLowerCase()
        .compareTo(b.category.name.toLowerCase()));
    return groups;
  }

  Widget _groupTile(_ReportGroup g, ThemeData theme, String sym) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(g.category.icon, size: 18, color: g.category.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(g.category.name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Text(
                Money.format(g.total, '', symbol: sym),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: g.total < 0
                      ? theme.colorScheme.error
                      : const Color(0xFF06D6A0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...g.items.map(
            (Transaction t) => Padding(
              padding: const EdgeInsets.only(left: 26, top: 2, bottom: 2),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 76,
                    child: Text(DateHelpers.full.format(t.date),
                        style: theme.textTheme.bodySmall),
                  ),
                  Expanded(
                    child: Text(
                      t.description.trim().isEmpty
                          ? g.category.name
                          : t.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    '${t.type == TransactionType.income ? '+' : '-'} ${Money.format(t.amount.abs(), '', symbol: sym)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: t.type == TransactionType.income
                          ? const Color(0xFF06D6A0)
                          : theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  Future<void> _pickCategories(FinanceController finance) async {
    final Set<String> temp = <String>{..._selectedCategories};
    final Set<String>? result = await showDialog<Set<String>>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setLocal) => AlertDialog(
          title: const Text('Escolher categorias'),
          content: SizedBox(
            width: double.maxFinite,
            child: finance.categories.isEmpty
                ? const Text('Nenhuma categoria cadastrada.')
                : ListView(
                    shrinkWrap: true,
                    children: finance.categories
                        .map((Category c) => CheckboxListTile(
                              value: temp.contains(c.id),
                              onChanged: (bool? v) {
                                setLocal(() {
                                  if (v == true) {
                                    temp.add(c.id);
                                  } else {
                                    temp.remove(c.id);
                                  }
                                });
                              },
                              secondary: Icon(c.icon, color: c.color),
                              title: Text(c.name),
                            ))
                        .toList(),
                  ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, temp),
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedCategories
          ..clear()
          ..addAll(result);
      });
    }
  }

  Future<void> _exportPdf(
      FinanceController finance, DateTime from, DateTime to, String sym) async {
    try {
      final File file = await PdfReportService().buildCategoryReport(
        finance: finance,
        categoryIds: _selectedCategories.toList(),
        from: from,
        to: to,
        periodLabel: _catPeriodLabel(),
        symbol: sym,
      );
      await Share.shareXFiles(
        <XFile>[XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Relatório ZOOM - ${_catPeriodLabel()}',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível exportar agora')),
        );
      }
    }
  }

  Widget _barChart(
      FinanceController finance, ThemeData theme, String sym) {
    final List<MapEntry<DateTime, double>> income =
        finance.monthlySeries(6, type: TransactionType.income);
    final List<MapEntry<DateTime, double>> expense =
        finance.monthlySeries(6, type: TransactionType.expense);

    double maxY = 0;
    for (int i = 0; i < income.length; i++) {
      maxY = maxY > income[i].value ? maxY : income[i].value;
      maxY = maxY > expense[i].value ? maxY : expense[i].value;
    }
    maxY = maxY <= 0 ? 100 : maxY * 1.25;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              getTitlesWidget: (double value, TitleMeta meta) => Text(
                Money.compact(value, sym, space: false),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: theme.textTheme.labelSmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int i = value.toInt();
                if (i < 0 || i >= income.length) {
                  return const SizedBox.shrink();
                }
                final String label = DateHelpers.monthShort
                    .format(income[i].key)
                    .replaceAll('.', '');
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: theme.textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List<BarChartGroupData>.generate(income.length, (int i) {
          return BarChartGroupData(
            x: i,
            barsSpace: 4,
            barRods: <BarChartRodData>[
              BarChartRodData(
                toY: income[i].value,
                color: const Color(0xFF06D6A0),
                width: 9,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: expense[i].value,
                color: const Color(0xFFEF476F),
                width: 9,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _export(
    List<Transaction> list,
    double income,
    double expense,
    Map<String, double> byCategory,
    String sym,
    FinanceController finance,
  ) async {
    final StringBuffer csv = StringBuffer();
    csv.writeln('Data;Tipo;Categoria;Descricao;Valor');
    for (final Transaction t in list) {
      final Category? c = finance.categoryById(t.categoryId);
      csv.writeln(
        '${DateHelpers.full.format(t.date)};'
        '${t.type == TransactionType.income ? 'Receita' : 'Despesa'};'
        '${c?.name ?? ''};'
        '${t.description.replaceAll(';', ',')};'
        '${t.amount.toStringAsFixed(2).replaceAll('.', ',')}',
      );
    }
    csv.writeln();
    csv.writeln('Resumo ($_periodLabel());');
    csv.writeln('Entradas;${income.toStringAsFixed(2).replaceAll('.', ',')}');
    csv.writeln('Saidas;${expense.toStringAsFixed(2).replaceAll('.', ',')}');
    csv.writeln();
    csv.writeln('Despesas por categoria;');
    byCategory.entries.toList().forEach((MapEntry<String, double> e) {
      final Category? c = finance.categoryById(e.key);
      csv.writeln('${c?.name ?? ''};${e.value.toStringAsFixed(2).replaceAll('.', ',')}');
    });

    try {
      final Directory dir = await getTemporaryDirectory();
      final File file = File(
          '${dir.path}${Platform.pathSeparator}relatorio_zoom.csv');
      await file.writeAsString(csv.toString(), encoding: utf8);
      await Share.shareXFiles(
        <XFile>[XFile(file.path, mimeType: 'text/csv')],
        subject: 'Relatório ZOOM - ${_periodLabel()}',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível exportar agora')),
        );
      }
    }
  }
}

class _ReportGroup {
  _ReportGroup(this.category, this.items, this.total);

  final Category category;
  final List<Transaction> items;
  final double total;
}
