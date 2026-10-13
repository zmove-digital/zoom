import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/id_generator.dart';
import '../../data/models/account.dart';
import '../../data/models/category.dart';
import '../../data/models/goal.dart';import '../../state/finance_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FinanceController finance = context.watch<FinanceController>();
    final SettingsController settings = context.watch<SettingsController>();
    final String sym = settings.currencySymbol;

    return AppScaffold(
      title: 'Metas',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Nova meta'),
      ),
      body: finance.goals.isEmpty
          ? EmptyState(
              icon: Icons.flag_outlined,
              title: 'Nenhuma meta ainda',
              message:
                  'Crie metas como "viagem", "celular novo" e acompanhe o progresso.',
              action: FilledButton.icon(
                onPressed: () => _openEditor(context, null),
                icon: const Icon(Icons.add),
                label: const Text('Criar meta'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: finance.goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final Goal g = finance.goals[index];
                return SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorFromHex(g.colorHex)
                                  .withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              kIconsByCodePoint[g.iconCodePoint] ?? Icons.flag,
                              color: colorFromHex(g.colorHex),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(g.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w700)),
                                Text(
                                  '${Money.format(g.savedAmount, '', symbol: sym)} de ${Money.format(g.targetAmount, '', symbol: sym)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _openEditor(context, g),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: g.progress.toDouble(),
                          minHeight: 12,
                          color: colorFromHex(g.colorHex),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text('${(g.progress * 100).toStringAsFixed(0)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          if (g.deadline != null)
                            Text(
                              'até ${DateHelpers.full.format(g.deadline!)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _contribute(context, g, sym),
                              icon: const Icon(Icons.add),
                              label: const Text('Guardar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _contribute(
      BuildContext context, Goal goal, String sym) async {
    final FinanceController finance = context.read<FinanceController>();
    final List<Account> accounts = finance.accounts;
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crie uma conta primeiro')),
      );
      return;
    }
    final (double, String)? result = await showDialog<(double, String)>(
      context: context,
      builder: (BuildContext ctx) => _ContributeDialog(
        goal: goal,
        accounts: accounts,
        sym: sym,
      ),
    );
    if (result != null && result.$1 > 0 && context.mounted) {
      finance.contributeToGoal(goal.id, result.$2, result.$1);
    }
  }

  void _openEditor(BuildContext context, Goal? goal) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _GoalEditor(goal: goal),
    );
  }
}

class _ContributeDialog extends StatefulWidget {
  const _ContributeDialog({
    required this.goal,
    required this.accounts,
    required this.sym,
  });

  final Goal goal;
  final List<Account> accounts;
  final String sym;

  @override
  State<_ContributeDialog> createState() => _ContributeDialogState();
}

class _ContributeDialogState extends State<_ContributeDialog> {
  final TextEditingController _amount = TextEditingController();
  final FocusNode _amountFocus = FocusNode();
  late String _accountId = widget.accounts.first.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _amountFocus.requestFocus());
  }

  @override
  void dispose() {
    _amount.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Guardar em "${widget.goal.name}"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _amount,
            focusNode: _amountFocus,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                labelText: 'Valor', prefixText: '${widget.sym} '),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _accountId,
            decoration: const InputDecoration(
              labelText: 'Conta de origem',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
            ),
            items: widget.accounts
                .map(
                  (Account a) => DropdownMenuItem<String>(
                    value: a.id,
                    child: Row(
                      children: <Widget>[
                        Icon(a.icon, size: 18, color: a.color),
                        const SizedBox(width: 8),
                        Flexible(
                          child:
                              Text(a.name, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (String? v) {
              if (v != null) {
                setState(() => _accountId = v);
                _amountFocus.requestFocus();
              }
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, (Money.parse(_amount.text), _accountId)),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _GoalEditor extends StatefulWidget {
  const _GoalEditor({this.goal});

  final Goal? goal;

  @override
  State<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends State<_GoalEditor> {
  late TextEditingController _name;
  late TextEditingController _target;
  late String _colorHex;
  late int _icon;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    final Goal? g = widget.goal;
    _name = TextEditingController(text: g?.name ?? '');
    _target = TextEditingController(
      text: g == null ? '' : g.targetAmount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _colorHex = g?.colorHex ?? kPaletteHex[2];
    _icon = g?.iconCodePoint ?? kCategoryIconChoices.first;
    _deadline = g?.deadline;
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  void _save() {
    final FinanceController finance = context.read<FinanceController>();
    final String name = _name.text.trim();
    final double target = Money.round2(Money.parse(_target.text));
    if (name.isEmpty || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome e valor da meta')),
      );
      return;
    }
    if (widget.goal == null) {
      finance.addGoal(
        Goal(
          id: newId(),
          name: name,
          targetAmount: target,
          deadline: _deadline,
          colorHex: _colorHex,
          iconCodePoint: _icon,
        ),
      );
    } else {
      finance.updateGoal(
        widget.goal!.copyWith(
          name: name,
          targetAmount: target,
          deadline: _deadline,
          colorHex: _colorHex,
          iconCodePoint: _icon,
        ),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.goal == null ? 'Nova meta' : 'Editar meta',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nome da meta'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _target,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor alvo'),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              ),
              leading: const Icon(Icons.event_outlined),
              title: const Text('Prazo'),
              subtitle: Text(_deadline == null
                  ? 'Sem prazo'
                  : DateHelpers.full.format(_deadline!)),
              trailing: _deadline == null
                  ? const Icon(Icons.chevron_right)
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _deadline = null),
                    ),
              onTap: _pickDeadline,
            ),
            const SizedBox(height: 18),
            Text('Cor', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: kPaletteHex.map((String hex) {
                final bool selected = hex == _colorHex;
                return GestureDetector(
                  onTap: () => setState(() => _colorHex = hex),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colorFromHex(hex),
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color: theme.colorScheme.onSurface, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                if (widget.goal != null)
                  IconButton.filledTonal(
                    onPressed: () {
                      context.read<FinanceController>().deleteGoal(
                            widget.goal!.id,
                          );
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
