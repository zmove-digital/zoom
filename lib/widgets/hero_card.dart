import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/utils/formatters.dart';

class HeroCard extends StatelessWidget {
  const HeroCard({
    required this.balance,
    required this.currencySymbol,
    required this.hidden,
    required this.onToggleHidden,
    super.key,
  });

  final double balance;
  final String currencySymbol;
  final bool hidden;
  final VoidCallback onToggleHidden;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const Color onHero = Color(0xFFFFFFFF);
    final String masked =
        currencySymbol.isEmpty ? '••••••' : '$currencySymbol ••••••';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: kHeroGradient,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: kHeroGradient.last.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: <Widget>[
            _shineBand(),
            _glowCircle(
              alignment: const Alignment(1.2, -1.3),
              color: const Color(0xFFF472B6),
            ),
            _glowCircle(
              alignment: const Alignment(-1.4, 1.4),
              color: const Color(0xFF22D3EE),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.account_balance_wallet_outlined,
                          color: onHero, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Saldo total',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: onHero),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: onToggleHidden,
                        tooltip: hidden ? 'Mostrar saldo' : 'Ocultar saldo',
                        visualDensity: VisualDensity.compact,
                        iconSize: 22,
                        icon: Icon(
                          hidden
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: onHero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      hidden
                          ? masked
                          : Money.format(balance, '', symbol: currencySymbol),
                      maxLines: 1,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: onHero,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shineBand() {
    return Positioned(
      left: -70,
      top: -60,
      bottom: -60,
      width: 130,
      child: Transform.rotate(
        angle: -0.5,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                Color(0x33FFFFFF),
                Color(0x00FFFFFF),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glowCircle({required Alignment alignment, required Color color}) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
