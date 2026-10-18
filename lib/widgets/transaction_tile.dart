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
    this.accountName,
    this.onTap,
    this.onLongPress,
    this.onSettle,
    super.key,
  });

  final Transaction transaction;
  final Category? category;
  final String currencySymbol;
  final String? accountName;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSettle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color errorColor = theme.colorScheme.error;
    final bool isIncome = transaction.type == TransactionType.income;
    final bool settled = transaction.isSettled;
    final bool overdue = transaction.isOverdue;
    final Color amountColor =
        overdue ? errorColor : (isIncome ? const Color(0xFF06D6A0) : errorColor);
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
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: overdue ? errorColor : null,
        ),
      ),
      subtitle: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              '${category?.name ?? 'Sem categoria'}${accountName != null ? ' • $accountName' : ''} • ${DateHelpers.full.format(transaction.date)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: overdue
                  ? theme.textTheme.bodyMedium?.copyWith(color: errorColor)
                  : null,
            ),
          ),
          if (overdue) ...<Widget>[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: errorColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'VENCIDO',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: errorColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
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
                    Icon(Icons.check_circle_outline,
                        size: 13,
                        color:
                            overdue ? errorColor : const Color(0xFFF4A261)),
                    const SizedBox(width: 3),
                    Text(
                      'Efetivar',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color:
                            overdue ? errorColor : const Color(0xFFF4A261),
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
