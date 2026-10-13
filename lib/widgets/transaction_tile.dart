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
    this.onSettle,
    super.key,
  });

  final Transaction transaction;
  final Category? category;
  final String currencySymbol;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSettle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isIncome = transaction.type == TransactionType.income;
    final bool settled = transaction.isSettled;
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
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            '${isIncome ? '+' : '-'} ${Money.format(transaction.amount.abs(), '', symbol: currencySymbol)}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          if (!settled && onSettle != null)
            InkWell(
              onTap: onSettle,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.check_circle_outline,
                        size: 13, color: Color(0xFFF4A261)),
                    const SizedBox(width: 3),
                    Text(
                      'Efetivar',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: const Color(0xFFF4A261),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  settled ? Icons.check_circle : Icons.schedule,
                  size: 13,
                  color: settled
                      ? const Color(0xFF06D6A0)
                      : const Color(0xFFF4A261),
                ),
                const SizedBox(width: 3),
                Text(
                  settled
                      ? 'Efetivado'
                      : (isIncome ? 'A receber' : 'A pagar'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: settled
                        ? const Color(0xFF06D6A0)
                        : const Color(0xFFF4A261),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
