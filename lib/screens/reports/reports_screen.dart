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

  _PieMode get _nextPieMode =>
      _PieMode.values[(_pieMode.index + 1) % _PieMode.values.length];

  (DateTime, DateTime) _range() {
    final DateTime now = DateTime.now();
    switch (_period) {
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
        final DateTime from =
            _customFrom ?? DateHelpers.startOfMonth(now);
        final DateTime to = _customTo ?? DateHelpers.endOfMonth(now);
        return (from, DateTime(to.year, to.month, to.day, 23, 59, 59));
    }
  }

  String _periodLabel() {
    switch (_period) {
      case _Period.month:
        return 'Este mês';
      case _Period.last30:
        return 'Últimos 30 dias';
      case _Period.year:
        return 'Este ano';
      case _Period.all:
        return 'Tudo';
      case _Period.custom:
        if (_customFrom != null && _customTo != null) {
          return '${DateHelpers.full.format(_customFrom!)} a ${DateHelpers.full.format(_customTo!)}';
        }
        return 'Período personalizado';
    }
  }

  Future<void> _pickCustomRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: (_customFrom != null && _customTo != null)
          ? DateTimeRange(start: _customFrom!, end: _customTo!)
          : DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: DateTime(now.year, now.month, now.day),
            ),
    );
    if (picked != null) {
      setState(() {
        _customFrom = picked.start;
        _customTo = picked.end;
        _period = _Period.custom;
      });
    }
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
