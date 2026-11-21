import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoom/core/theme/app_theme.dart';
import 'package:zoom/data/models/app_settings.dart';
import 'package:zoom/data/storage/local_database.dart';
import 'package:zoom/state/settings_controller.dart';
import 'package:zoom/widgets/hero_card.dart';

void main() {
  test('resetAppearance restaura a aparência e preserva dados do usuário', () {
    final LocalDatabase db = LocalDatabase.inMemory();
    final SettingsController settings = SettingsController(db);

    settings.update(
      (AppSettings s) => s.copyWith(
        userName: 'Rezende',
        currencyCode: 'USD',
        backupEmail: 'rezende@example.com',
        pinEnabled: true,
        pin: '1234',
        soundEnabled: false,
        themeMode: AppThemeMode.dark,
        seedColorHex: 'FF0000',
        accentColorHex: '00FF00',
        backgroundImagePath: '/tmp/fundo.png',
        backgroundOpacity: 0.6,
        cardOpacity: 0.5,
        fontScale: 1.4,
        useRoundedCards: false,
        hideBalance: true,
      ),
    );

    settings.resetAppearance();

    expect(settings.settings.themeMode, AppThemeMode.system);
    expect(settings.settings.seedColorHex, '6C5CE7');
    expect(settings.settings.accentColorHex, '00B894');
    expect(settings.settings.backgroundImagePath, isNull);
    expect(settings.settings.backgroundOpacity, 0.12);
    expect(settings.settings.cardOpacity, 1.0);
    expect(settings.settings.fontScale, 1.0);
    expect(settings.settings.useRoundedCards, isTrue);
    expect(settings.settings.hideBalance, isFalse);

    expect(settings.settings.userName, 'Rezende');
    expect(settings.settings.currencyCode, 'USD');
    expect(settings.settings.backupEmail, 'rezende@example.com');
    expect(settings.settings.pinEnabled, isTrue);
    expect(settings.settings.pin, '1234');
    expect(settings.settings.soundEnabled, isFalse);

    // As alterações foram persistidas.
    final SettingsController reloaded = SettingsController(db);
    expect(reloaded.settings.fontScale, 1.0);
    expect(reloaded.settings.userName, 'Rezende');
    expect(reloaded.settings.currencyCode, 'USD');
  });

  testWidgets('saldo do card permanece grande com qualquer tamanho de fonte', (
    WidgetTester tester,
  ) async {
    Future<double> fontSizeFor(double fontScale) async {
      final AppSettings settings = AppSettings(fontScale: fontScale);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(settings, Brightness.light),
          home: Scaffold(
            body: HeroCard(
              balance: 1234.56,
              currencySymbol: r'R$',
              hidden: false,
              onToggleHidden: () {},
            ),
          ),
        ),
      );
      final Text text = tester.widget<Text>(
        find.byWidgetPredicate(
          (Widget w) => w is Text && (w.data ?? '').contains('1.234,56'),
        ),
      );
      return text.style!.fontSize!;
    }

    final double normal = await fontSizeFor(1.0);
    final double enlarged = await fontSizeFor(1.4);

    expect(normal, greaterThanOrEqualTo(34));
    expect(enlarged, normal);
  });
}
