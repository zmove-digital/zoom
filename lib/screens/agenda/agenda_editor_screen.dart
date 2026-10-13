import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/agenda_entry.dart';
import '../../data/models/category.dart';
import '../../state/agenda_controller.dart';

class AgendaEditorScreen extends StatefulWidget {
  const AgendaEditorScreen({this.existing, this.initialDate, super.key});

  final AgendaEntry? existing;
  final DateTime? initialDate;

  @override
  State<AgendaEditorScreen> createState() => _AgendaEditorScreenState();
}

class _AgendaEditorScreenState extends State<AgendaEditorScreen> {
  late TextEditingController _title;
  late TextEditingController _content;
  late TextEditingController _tagInput;
  late DateTime _date;
  late Mood _mood;
  late String _colorHex;
  late List<String> _tags;
  late int _rating;

  @override
  void initState() {
    super.initState();
    final AgendaEntry? e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _content = TextEditingController(text: e?.content ?? '');
    _tagInput = TextEditingController();
    _date = e?.date ?? widget.initialDate ?? DateTime.now();
    _mood = e?.mood ?? Mood.neutral;
    _colorHex = e?.colorHex ?? kPaletteHex.first;
    _tags = List<String>.from(e?.tags ?? <String>[]);
    _rating = e?.rating ?? 0;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _tagInput.dispose();
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

  String _moodLabel(Mood m) {
    switch (m) {
      case Mood.great:
        return 'Ótimo';
      case Mood.good:
        return 'Bom';
      case Mood.neutral:
        return 'Neutro';
      case Mood.bad:
        return 'Ruim';
      case Mood.awful:
        return 'Péssimo';
    }
  }

  void _addTag() {
    final String tag = _tagInput.text.trim();
    if (tag.isEmpty) return;
    if (!_tags.contains(tag)) {
      setState(() => _tags.add(tag));
    }
    _tagInput.clear();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _save() {
    final AgendaController controller = context.read<AgendaController>();
    if (_title.text.trim().isEmpty && _content.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escreva algo antes de salvar')),
      );
      return;
    }

    if (widget.existing == null) {
      final AgendaEntry entry = controller.blankFor(_date)
        ..title = _title.text.trim()
        ..content = _content.text
        ..mood = _mood
        ..colorHex = _colorHex
        ..tags = _tags
        ..rating = _rating;
      controller.add(entry);
    } else {
      controller.update(
        widget.existing!.copyWith(
          date: _date,
          title: _title.text.trim(),
          content: _content.text,
          mood: _mood,
          colorHex: _colorHex,
          tags: _tags,
          rating: _rating,
        ),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(widget.existing == null ? 'Nova anotação' : 'Editar'),
        actions: <Widget>[
          if (widget.existing != null)
            IconButton(
              onPressed: () {
                context.read<AgendaController>().delete(widget.existing!.id);
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.delete_outline),
            ),
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check),
            tooltip: 'Salvar',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: <Widget>[
          Row(
            children: <Widget>[
              ActionChip(
                avatar: const Icon(Icons.event, size: 18),
                label: Text(DateHelpers.full.format(_date)),
                onPressed: _pickDate,
              ),
              const Spacer(),
              ...Mood.values.map(
                (Mood m) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _mood = m),
                    child: Icon(
                      _moodIcon(m),
                      size: 26,
                      color: _mood == m
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Humor: ${_moodLabel(_mood)}',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Text('Nota do dia', style: theme.textTheme.titleSmall),
              const SizedBox(width: 12),
              ...List<Widget>.generate(5, (int i) {
                final int star = i + 1;
                final bool filled = _rating >= star;
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: GestureDetector(
                    onTap: () => setState(
                        () => _rating = _rating == star ? 0 : star),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 32,
                      color: filled
                          ? const Color(0xFFFFB703)
                          : theme.colorScheme.outline,
                    ),
                  ),
                );
              }),
              const SizedBox(width: 6),
              Text(
                _rating == 0 ? 'sem nota' : '$_rating/5',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              hintText: 'Título do dia...',
              border: InputBorder.none,
              filled: false,
            ),
          ),
          const Divider(),
          TextField(
            controller: _content,
            maxLines: null,
            minLines: 10,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText:
                  'Escreva livremente sobre o seu dia, seus planos, sentimentos...',
              border: InputBorder.none,
              filled: false,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _tagInput,
                  decoration: const InputDecoration(
                    labelText: 'Adicionar tag',
                    prefixIcon: Icon(Icons.tag),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _addTag,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags
                  .map(
                    (String tag) => Chip(
                      label: Text(tag),
                      onDeleted: () => setState(() => _tags.remove(tag)),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 20),
          Text('Cor da anotação', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: kPaletteHex.map((String hex) {
              final bool selected = hex == _colorHex;
              return GestureDetector(
                onTap: () => setState(() => _colorHex = hex),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorFromHex(hex),
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salvar anotação'),
            ),
          ),
        ],
      ),
    );
  }
}
