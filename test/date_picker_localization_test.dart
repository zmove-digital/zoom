import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('date picker displays Brazilian Portuguese labels', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        supportedLocales: const <Locale>[Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
          builder:
              (BuildContext context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () {
                      showDatePicker(
                        context: context,
                        initialDate: DateTime(2026, 10, 31),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                    },
                    child: const Text('Abrir calendário'),
                  ),
                ),
              ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir calendário'));
    await tester.pumpAndSettle();

    expect(find.text('outubro de 2026'), findsOneWidget);
    expect(find.text('Selecione a data'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });
}
