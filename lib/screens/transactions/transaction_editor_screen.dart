import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/id_generator.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../services/sound_service.dart';
import '../../state/finance_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/recurrence_scope_dialog.dart';

class TransactionEditorScreen extends StatefulWidget {
  const TransactionEditorScreen({this.existing, this.initialType, super.key});

  final Transaction? existing;
  final TransactionType? initialType;

  @override
  State<TransactionEditorScreen> createState() =>
      _TransactionEditorScreenState();
}

class _TransactionEditorScreenState extends State<TransactionEditorScreen> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  late TransactionType _type;
  late DateTime _date;
  String? _categoryId;
  RecurrencePeriod? _repeat;
  bool? _paid;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final Transaction? e = widget.existing;
    _type = e?.type ?? widget.initialType ?? TransactionType.expense;
    _date = e?.date ?? DateTime.now();
    _categoryId = e?.categoryId;
    _repeat = e?.recurrence;
    _paid = e?.isPaid;
    if (e != null) {
      _amount.text = e.amount.toStringAsFixed(2).replaceAll('.', ',');
      _description.text = e.description;
      _notes.text = e.notes;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  List<Category> _categories(FinanceController finance) {
    return _type == TransactionType.income
        ? finance.incomeCategories
        : finance.expenseCategories;
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(picked.year, picked.month, picked.day, _date.hour,
            _date.minute);
      });
    }
  }

  Widget _repeatSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: <Widget>[
              Icon(Icons.repeat, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'REPETIR',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ChoiceChip(
              label: const Text('Nenhuma'),
              selected: _repeat == null,
              onSelected: (_) => setState(() => _repeat = null),
            ),
            ...RecurrencePeriod.values.map(
              (RecurrencePeriod p) => ChoiceChip(
                label: Text(p.label),
                selected: _repeat == p,
                onSelected: (_) => setState(() => _repeat = p),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusSelector(ThemeData theme) {
    final bool income = _type == TransactionType.income;
    final String doneLabel = income ? 'Recebido' : 'Pago';
    final String pendingLabel = income ? 'A receber' : 'A pagar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: <Widget>[
              Icon(Icons.check_circle_outline,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'EFETIVAÇÃO',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ChoiceChip(
              label: const Text('Automático'),
              selected: _paid == null,
              onSelected: (_) => setState(() => _paid = null),
            ),
            ChoiceChip(
              label: Text(doneLabel),
              selected: _paid == true,
              onSelected: (_) => setState(() => _paid = true),
            ),
            ChoiceChip(
              label: Text(pendingLabel),
              selected: _paid == false,
              onSelected: (_) => setState(() => _paid = false),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Automático usa a data: passado conta como $doneLabel, futuro como $pendingLabel.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final FinanceController finance = context.read<FinanceController>();
    final SoundService sound = context.read<SoundService>();
    final SettingsController settings = context.read<SettingsController>();

    final double value = Money.round2(Money.parse(_amount.text));
    if (value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor maior que zero')),
      );
      return;
    }
    final String catId = _categoryId ??
        (_categories(finance).isNotEmpty ? _categories(finance).first.id : '');
    if (catId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crie uma categoria primeiro')),
      );
      return;
    }

    final Transaction tx = Transaction(
      id: widget.existing?.id ?? newId(),
      type: _type,
      amount: value,
      categoryId: catId,
      date: _date,
      description: _description.text.trim(),
      notes: _notes.text.trim(),
      isPaid: _paid,
      createdAt: widget.existing?.createdAt,
    );

    if (!_isEditing) {
      finance.addTransaction(tx, repeat: _repeat);
    } else {
      final Transaction original = widget.existing!;
      if (original.recurrenceId == null) {
        if (_repeat == null) {
          finance.updateTransaction(tx);
        } else {
          finance.makeRecurringFrom(tx, _repeat!);
        }
      } else {
        final RecurrenceScope? scope = await showEditScopeDialog(context);
        if (scope == null) return;
        finance.updateTransactionSeries(
          tx,
          includeFuture: scope == RecurrenceScope.thisAndFuture,
          repeat: _repeat,
        );
      }
    }

    await sound.playTap(
      path: settings.settings.tapSoundPath,
      enabled: settings.settings.soundEnabled,
      haptics: settings.settings.hapticsEnabled,
    );

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final FinanceController finance = context.read<FinanceController>();
    final Transaction? original = widget.existing;
    if (original == null) return;
    if (original.recurrenceId == null) {
      finance.deleteTransaction(original.id);
    } else {
      final RecurrenceScope? scope = await showDeleteScopeDialog(context);
      if (scope == null) return;
      finance.deleteTransactionSeries(
        original.id,
        includeFuture: scope == RecurrenceScope.thisAndFuture,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final FinanceController finance = context.watch<FinanceController>();
    final SettingsController settings = context.watch<SettingsController>();
    final ThemeData theme = Theme.of(context);
    final List<Category> cats = _categories(finance);
    if (_categoryId == null && cats.isNotEmpty) {
      _categoryId = cats.first.id;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(_isEditing ? 'Editar lançamento' : 'Novo lançamento'),
        actions: <Widget>[
          if (_isEditing)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Excluir',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: <Widget>[
          SegmentedButton<TransactionType>(
            segments: const <ButtonSegment<TransactionType>>[
              ButtonSegment<TransactionType>(
                value: TransactionType.expense,
                label: Text('Despesa'),
                icon: Icon(Icons.arrow_downward),
              ),
              ButtonSegment<TransactionType>(
                value: TransactionType.income,
                label: Text('Receita'),
                icon: Icon(Icons.arrow_upward),
              ),
            ],
            selected: <TransactionType>{_type},
            onSelectionChanged: (Set<TransactionType> value) {
              setState(() {
                _type = value.first;
                _categoryId = null;
              });
            },
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _amount,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: 'Valor',
              prefixText: '${settings.currencySymbol} ',
              prefixIcon: const Icon(Icons.attach_money),
            ),
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _categoryId,
            decoration: const InputDecoration(
              labelText: 'Categoria',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: cats
                .map(
                  (Category c) => DropdownMenuItem<String>(
                    value: c.id,
                    child: Row(
                      children: <Widget>[
                        Icon(c.icon, size: 18, color: c.color),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (String? v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _description,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Descrição',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            leading: const Icon(Icons.event_outlined),
            title: const Text('Data'),
            subtitle: Text(DateHelpers.full.format(_date)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          _statusSelector(theme),
          const SizedBox(height: 16),
          _repeatSelector(theme),
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Observações (opcional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(_isEditing ? 'Salvar alterações' : 'Adicionar'),
            ),
          ),
        ],
      ),
    );
  }
}
