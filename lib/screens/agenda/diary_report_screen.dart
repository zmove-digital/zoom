import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/agenda_entry.dart';
import '../../state/agenda_controller.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/section_card.dart';

enum _RatingPeriod { month, semester, year }

class DiaryReportScreen extends StatefulWidget {
  const DiaryReportScreen({super.key});

  @override
  State<DiaryReportScreen> createState() => _DiaryReportScreenState();
}

class _DiaryReportScreenState extends State<DiaryReportScreen> {
  _RatingPeriod _period = _RatingPeriod.month;

  static const Color _star = Color(0xFFFFB703);

  (DateTime, DateTime) _range() {
    final DateTime now = DateTime.now();
    switch (_period) {
      case _RatingPeriod.month:
        return (
          DateHelpers.startOfMonth(now),
          DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case _RatingPeriod.semester:
        final bool first = now.month <= 6;
        final int startMonth = first ? 1 : 7;
        return (
          DateTime(now.year, startMonth),
          DateTime(now.year, startMonth + 6, 0, 23, 59, 59),
        );
      case _RatingPeriod.year:
        return (DateTime(now.year), DateTime(now.year, 12, 31, 23, 59, 59));
    }
  }

  String _periodLabel() {
    switch (_period) {
      case _RatingPeriod.month:
        return 'Este mês';
      case _RatingPeriod.semester:
        return 'Este semestre';
      case _RatingPeriod.year:
        return 'Este ano';
    }
  }

  String _periodChip(_RatingPeriod p) {
    switch (p) {
      case _RatingPeriod.month:
        return 'Mês';
      case _RatingPeriod.semester:
        return 'Semestre';
      case _RatingPeriod.year:
        return 'Ano';
    }
  }

  String _rangeLabel(DateTime from, DateTime to) =>
      '${DateHelpers.dayMonth.format(from)} - ${DateHelpers.dayMonth.format(to)}';

  List<AgendaEntry> _rated(List<AgendaEntry> entries) {
    final (DateTime from, DateTime to) = _range();
    return entries
        .where((AgendaEntry e) =>
            e.rating > 0 &&
            !e.date.isBefore(from) &&
            !e.date.isAfter(to))
        .toList()
      ..sort((AgendaEntry a, AgendaEntry b) => b.date.compareTo(a.date));
  }

  @override
  Widget build(BuildContext context) {
    final AgendaController agenda = context.watch<AgendaController>();
    final ThemeData theme = Theme.of(context);
    final List<AgendaEntry> rated = _rated(agenda.entries);

    final int count = rated.length;
    final double average = count == 0
        ? 0
        : rated.fold<int>(0, (int s, AgendaEntry e) => s + e.rating) / count;

    final Map<int, int> distribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final AgendaEntry e in rated) {
      distribution[e.rating] = (distribution[e.rating] ?? 0) + 1;
    }
    final (DateTime from, DateTime to) = _range();

    return AppScaffold(
      title: 'Relatório do Diário',
      actions: <Widget>[
        IconButton(
          onPressed: rated.isEmpty ? null : () => _export(rated, average),
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
              children: _RatingPeriod.values.map((_RatingPeriod p) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_periodChip(p)),
                    selected: _period == p,
                    onSelected: (_) => setState(() => _period = p),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              children: <Widget>[
                Text('Nota média do período',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 10),
                Text(
                  count == 0 ? '—' : average.toStringAsFixed(1),
                  style: theme.textTheme.displaySmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                _StarRow(value: average, size: 30, color: _star),
                const SizedBox(height: 10),
                Text(
                  '${_periodLabel()} • ${_rangeLabel(from, to)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: StatCard(
                  label: 'Dias avaliados',
                  value: '$count',
                  icon: Icons.event_available_rounded,
                  color: const Color(0xFF4361EE),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Notas 5 estrelas',
                  value: '${distribution[5]}',
                  icon: Icons.emoji_events_rounded,
                  color: _star,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Distribuição das notas',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (count == 0)
            SectionCard(
              child: SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    'Nenhuma nota registrada no período',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            SectionCard(
              child: Column(
                children: <Widget>[
                  for (int star = 5; star >= 1; star--)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: 28,
                            child: Text('$star',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                          ),
                          const Icon(Icons.star_rounded, size: 16, color: _star),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: count == 0
                                    ? 0
                                    : (distribution[star] ?? 0) / count,
                                minHeight: 10,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                color: _star,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 24,
                            child: Text('${distribution[star]}',
                                textAlign: TextAlign.end,
                                style: theme.textTheme.bodySmall),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (rated.isNotEmpty) ...<Widget>[
            const SizedBox(height: 20),
            Text('Últimos dias avaliados',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            SectionCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: rated.take(10).map((AgendaEntry e) {
                  return ListTile(
                    dense: true,
                    leading: _StarRow(
                        value: e.rating.toDouble(), size: 16, color: _star),
                    title: Text(
                      e.title.trim().isEmpty ? 'Sem título' : e.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(DateHelpers.full.format(e.date)),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _export(List<AgendaEntry> rated, double average) async {
    final StringBuffer csv = StringBuffer();
    csv.writeln('Data;Nota;Titulo;Humor');
    for (final AgendaEntry e in rated) {
      csv.writeln(
        '${DateHelpers.full.format(e.date)};'
        '${e.rating};'
        '${e.title.replaceAll(';', ',').trim()};'
        '${e.mood.name}',
      );
    }
    csv.writeln();
    csv.writeln('Resumo ($_periodLabel());');
    csv.writeln('Dias avaliados;${rated.length}');
    csv.writeln('Nota media;${average.toStringAsFixed(2).replaceAll('.', ',')}');

    try {
      final Directory dir = await getTemporaryDirectory();
      final File file = File(
          '${dir.path}${Platform.pathSeparator}relatorio_diario_zoom.csv');
      await file.writeAsString(csv.toString(), encoding: utf8);
      await Share.shareXFiles(
        <XFile>[XFile(file.path, mimeType: 'text/csv')],
        subject: 'Relatório do Diário ZOOM - ${_periodLabel()}',
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

class _StarRow extends StatelessWidget {
  const _StarRow({required this.value, required this.size, required this.color});

  final double value;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final int filled = value.round().clamp(0, 5);
    final Color empty = Theme.of(context).colorScheme.outlineVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(
        5,
        (int i) => Icon(
          i < filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: i < filled ? color : empty,
        ),
      ),
    );
  }
}
