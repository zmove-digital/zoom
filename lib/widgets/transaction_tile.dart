import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../data/models/category.dart';
import '../data/models/transaction.dart';
import 'category_avatar.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.transaction,
    required this.category,
    required this.currencySymbol,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final Transaction transaction;
  final Category? category;
  final String currencySymbol;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isIncome = transaction.type == TransactionType.income;
    final Color amountColor =
        isIncome ? const Color(0xFF06D6A0) : theme.colorScheme.error;
    final String title = transaction.description.trim().isEmpty
        ? (category?.name ?? 'Sem categoria')
        : transaction.description;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      onTap: onTap,
      onLongPress: onLongPress,
      leading: CategoryAvatar(category: category),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              '${category?.name ?? 'Sem categoria'} • ${DateHelpers.full.format(transaction.date)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (transaction.isRecurring) ...<Widget>[
            const SizedBox(width: 6),
            Icon(Icons.repeat, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 2),
            Text(
              transaction.recurrence!.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      trailing: Text(
        '${isIncome ? '+' : '-'} ${Money.format(transaction.amount.abs(), '', symbol: currencySymbol)}',
        style: theme.textTheme.titleSmall?.copyWith(
          color: amountColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
