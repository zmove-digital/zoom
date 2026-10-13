import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/agenda_entry.dart';
import '../../data/models/category.dart';
import '../../state/agenda_controller.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state.dart';
import 'agenda_editor_screen.dart';
import 'diary_report_screen.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  IconData _moodIcon(Mood m) {
    switch (m) {
      case Mood.great:
        return Icons.sentiment_very_satisfied;
      case Mood.good:
        return Icons.sentiment_satisfied;
      case Mood.neutral:
        return Icons.sentiment_neutral;
      case Mood.bad:
        return Icons.sentiment_dissatisfied;
      case Mood.awful:
        return Icons.sentiment_very_dissatisfied;
    }
  }

  Widget _ratingStars(int rating) {
    final Color empty = Theme.of(context).colorScheme.outlineVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(
        5,
        (int i) => Icon(
          i < rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: 14,
          color: i < rating ? const Color(0xFFFFB703) : empty,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AgendaController agenda = context.watch<AgendaController>();
    final ThemeData theme = Theme.of(context);
    final List<AgendaEntry> entries = agenda.search(_search.text);

    return AppScaffold(
      title: 'Diário',
      actions: <Widget>[
        IconButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const DiaryReportScreen()));
          },
          icon: const Icon(Icons.star_half_rounded),
          tooltip: 'Relatório do diário',
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const AgendaEditorScreen()));
        },
        icon: const Icon(Icons.create),
        label: const Text('Escrever'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Buscar no diário...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (agenda.entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  Icon(Icons.local_fire_department,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('Sequência de ${agenda.streak} dia(s)',
                      style: theme.textTheme.bodySmall),
                  const Spacer(),
                  Text('${agenda.entries.length} anotações',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: entries.isEmpty
                ? EmptyState(
                    icon: Icons.auto_stories_outlined,
                    title: _search.text.isEmpty
                        ? 'Seu diário está em branco'
                        : 'Nada encontrado',
                    message: _search.text.isEmpty
                        ? 'Escreva livremente sobre seu dia, suas metas e sentimentos. É o seu espaço.'
                        : 'Tente outra palavra.',
                    action: _search.text.isEmpty
                        ? FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute<void>(
                                  builder: (_) => const AgendaEditorScreen()));
                            },
                            icon: const Icon(Icons.create),
                            label: const Text('Começar a escrever'),
                          )
                        : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final AgendaEntry e = entries[index];
                      final Color color = colorFromHex(e.colorHex);
                      final String preview = e.content
                          .replaceAll('\n', ' ')
                          .trim();
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute<void>(
                              builder: (_) => AgendaEditorScreen(existing: e),
                            ));
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateHelpers.full.format(e.date),
                                      style: theme.textTheme.labelMedium,
                                    ),
                                    const Spacer(),
                                    if (e.rating > 0) ...<Widget>[
                                      _ratingStars(e.rating),
                                      const SizedBox(width: 8),
                                    ],
                                    Icon(_moodIcon(e.mood),
                                        size: 18,
                                        color: theme.colorScheme.outline),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  e.title.trim().isEmpty
                                      ? 'Sem título'
                                      : e.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (preview.isNotEmpty) ...<Widget>[
                                  const SizedBox(height: 4),
                                  Text(
                                    preview,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                if (e.tags.isNotEmpty) ...<Widget>[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: e.tags
                                        .map(
                                          (String t) => Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: withOpacity(color, 0.16),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text('#$t',
                                                style: theme
                                                    .textTheme.labelSmall),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
