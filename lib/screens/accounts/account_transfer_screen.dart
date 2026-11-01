import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/account.dart';
import '../../state/finance_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_scaffold.dart';

class AccountTransferScreen extends StatefulWidget {
  const AccountTransferScreen({super.key});

  @override
  State<AccountTransferScreen> createState() => _AccountTransferScreenState();
}

class _AccountTransferScreenState extends State<AccountTransferScreen> {
  final TextEditingController _amount = TextEditingController();
  String? _fromAccountId;
  String? _toAccountId;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _save(FinanceController finance) {
    final double amount = Money.round2(Money.parse(_amount.text));
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor maior que zero')),
      );
      return;
    }
    final String? fromAccountId = _fromAccountId;
    final String? toAccountId = _toAccountId;
    if (fromAccountId == null ||
        toAccountId == null ||
        fromAccountId == toAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha duas contas diferentes')),
      );
      return;
    }
    if (!finance.transferBetweenAccounts(
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amount: amount,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível fazer a transferência')),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final FinanceController finance = context.watch<FinanceController>();
    final String currencySymbol =
        context.watch<SettingsController>().currencySymbol;
    final ThemeData theme = Theme.of(context);
    final List<Account> accounts = finance.accounts;
    _fromAccountId ??= accounts.isNotEmpty ? accounts.first.id : null;
    _toAccountId ??= accounts.length > 1 ? accounts[1].id : null;

    return AppScaffold(
      title: 'Transferir entre contas',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          Text(
            'Transfira um valor entre suas contas. O saldo total não muda.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _fromAccountId,
            decoration: const InputDecoration(
              labelText: 'De',
              prefixIcon: Icon(Icons.call_made_rounded),
            ),
            items:
                accounts
                    .map(
                      (Account account) => DropdownMenuItem<String>(
                        value: account.id,
                        child: Text(account.name),
                      ),
                    )
                    .toList(),
            onChanged: (String? value) {
              setState(() {
                _fromAccountId = value;
                if (_toAccountId == value) {
                  _toAccountId =
                      accounts
                          .firstWhere((Account account) => account.id != value)
                          .id;
                }
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _toAccountId,
            decoration: const InputDecoration(
              labelText: 'Para',
              prefixIcon: Icon(Icons.call_received_rounded),
            ),
            items:
                accounts
                    .where((Account account) => account.id != _fromAccountId)
                    .map(
                      (Account account) => DropdownMenuItem<String>(
                        value: account.id,
                        child: Text(account.name),
                      ),
                    )
                    .toList(),
            onChanged: (String? value) => setState(() => _toAccountId = value),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: 'Valor',
              prefixText: '$currencySymbol ',
              prefixIcon: const Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: accounts.length < 2 ? null : () => _save(finance),
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Transferir'),
          ),
        ],
      ),
    );
  }
}
