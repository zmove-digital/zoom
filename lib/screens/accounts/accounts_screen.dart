import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/id_generator.dart';
import '../../data/models/account.dart';
import '../../data/models/category.dart';
import '../../state/finance_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FinanceController finance = context.watch<FinanceController>();
    final SettingsController settings = context.watch<SettingsController>();
    final ThemeData theme = Theme.of(context);
    final String sym = settings.currencySymbol;

    return AppScaffold(
      title: 'Contas',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Nova conta'),
      ),
      body: finance.accounts.isEmpty
          ? EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Nenhuma conta ainda',
              message:
                  'Crie contas como Carteira, Banco ou Cartão de Crédito e acompanhe o saldo de cada uma.',
              action: FilledButton.icon(
                onPressed: () => _openEditor(context, null),
                icon: const Icon(Icons.add),
                label: const Text('Criar conta'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: <Widget>[
                _totalCard(context, finance, sym, theme),
                const SizedBox(height: 16),
                ...finance.accounts.map(
                  (Account a) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _accountCard(context, finance, a, sym, theme),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _totalCard(BuildContext context, FinanceController finance,
      String sym, ThemeData theme) {
    final double total = finance.totalBalance;
    return SectionCard(
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.account_balance_wallet_rounded,
                color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Saldo total',
                    style: theme.textTheme.bodySmall),
                Text(
                  Money.format(total, '', symbol: sym),
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountCard(BuildContext context, FinanceController finance,
      Account a, String sym, ThemeData theme) {
    final double balance = finance.accountBalance(a.id);
    return SectionCard(
      onTap: () => _openEditor(context, a),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: a.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(a.icon, color: a.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(a.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(a.type.label, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            Money.format(balance, '', symbol: sym),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: balance < 0 ? theme.colorScheme.error : null,
            ),
          ),
        ],
      ),
    );
  }

  void _openEditor(BuildContext context, Account? account) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _AccountEditor(account: account),
    );
  }
}

class _AccountEditor extends StatefulWidget {
  const _AccountEditor({this.account});

  final Account? account;

  @override
  State<_AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends State<_AccountEditor> {
  late TextEditingController _name;
  late TextEditingController _initial;
  late AccountType _type;
  late String _colorHex;

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    final Account? a = widget.account;
    _name = TextEditingController(text: a?.name ?? '');
    _initial = TextEditingController(
      text: a == null || a.initialBalance == 0
          ? ''
          : a.initialBalance.toStringAsFixed(2).replaceAll('.', ','),
    );
    _type = a?.type ?? AccountType.checking;
    _colorHex = a?.colorHex ?? _type.defaultColorHex;
  }

  @override
  void dispose() {
    _name.dispose();
    _initial.dispose();
    super.dispose();
  }

  void _save() {
    final FinanceController finance = context.read<FinanceController>();
    final String name = _name.text.trim();
    final double initial = Money.round2(Money.parse(_initial.text));
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome da conta')),
      );
      return;
    }
    if (_isEditing) {
      finance.updateAccount(widget.account!.copyWith(
        name: name,
        type: _type,
        initialBalance: initial,
        colorHex: _colorHex,
      ));
    } else {
      finance.addAccount(Account(
        id: newId(),
        name: name,
        type: _type,
        initialBalance: initial,
        colorHex: _colorHex,
      ));
    }
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final FinanceController finance = context.read<FinanceController>();
    if (finance.accounts.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa de pelo menos uma conta')),
      );
      return;
    }
    final String fallback = finance.accounts
        .firstWhere((Account a) => a.id != widget.account!.id)
        .name;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: Text(
            'Os lançamentos e valores guardados desta conta serão movidos para "$fallback".'),
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
    if (ok == true && mounted) {
      finance.deleteAccount(widget.account!.id);
      Navigator.of(context).pop();
    }
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
              _isEditing ? 'Editar conta' : 'Nova conta',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nome da conta',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<AccountType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Tipo de conta',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              items: AccountType.values
                  .map(
                    (AccountType t) => DropdownMenuItem<AccountType>(
                      value: t,
                      child: Row(
                        children: <Widget>[
                          Icon(t.icon, size: 18),
                          const SizedBox(width: 8),
                          Text(t.label),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (AccountType? v) {
                if (v == null) return;
                setState(() {
                  _type = v;
                  _colorHex = v.defaultColorHex;
                });
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _initial,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Saldo inicial',
                prefixIcon: Icon(Icons.attach_money),
                helperText: 'Quanto já existe nesta conta hoje (opcional)',
              ),
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
                if (_isEditing)
                  IconButton.filledTonal(
                    onPressed: _confirmDelete,
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
