import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/storage/local_database.dart';
import 'services/backup_service.dart';
import 'services/media_service.dart';
import 'services/notification_service.dart';
import 'services/sound_service.dart';
import 'state/agenda_controller.dart';
import 'state/finance_controller.dart';
import 'state/reminder_controller.dart';
import 'state/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');

  final LocalDatabase db = await LocalDatabase.open();

  final SettingsController settingsController = SettingsController(db);
  final FinanceController financeController = FinanceController(db);
  final AgendaController agendaController = AgendaController(db);
  final ReminderController reminderController = ReminderController(db);

  final NotificationService notificationService = NotificationService();
  await notificationService.init();
  reminderController.scheduler = notificationService.scheduleAll;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsController>.value(value: settingsController),
        ChangeNotifierProvider<FinanceController>.value(value: financeController),
        ChangeNotifierProvider<AgendaController>.value(value: agendaController),
        ChangeNotifierProvider<ReminderController>.value(value: reminderController),
        Provider<NotificationService>.value(value: notificationService),
        Provider<BackupService>(create: (_) => BackupService(db)),
        Provider<MediaService>(create: (_) => MediaService()),
        Provider<SoundService>(create: (_) => SoundService()),
        Provider<LocalDatabase>.value(value: db),
      ],
      child: const GranaApp(),
    ),
  );
}
