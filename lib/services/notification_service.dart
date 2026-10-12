import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/constants.dart';
import '../data/models/reminder.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _exactAllowed = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'zoom_lembretes',
    'Lembretes e alarmes',
    description: 'Avisos de contas, metas e agenda do ZOOM',
    importance: Importance.max,
  );

  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      String name = 'America/Sao_Paulo';
      try {
        name = await FlutterTimezone.getLocalTimezone();
      } catch (_) {
        name = 'UTC';
      }
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings settings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    try {
      await _plugin.initialize(settings);
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(_channel);
      _ready = true;
    } catch (_) {
      _ready = true;
    }
  }

  Future<bool> requestPermissions() async {
    await init();
    try {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final bool? granted = await android?.requestNotificationsPermission();
      _exactAllowed = await android?.requestExactAlarmsPermission() ?? true;

      final IOSFlutterLocalNotificationsPlugin? ios =
          _plugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);

      final MacOSFlutterLocalNotificationsPlugin? mac =
          _plugin.resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>();
      await mac?.requestPermissions(alert: true, badge: true, sound: true);

      return granted ?? true;
    } catch (_) {
      return false;
    }
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    await init();
    if (!reminder.enabled) {
      await cancel(NotificationIds.alarmBase + reminder.id.hashCode.abs() % 900);
      return;
    }
    final int id = NotificationIds.alarmBase + reminder.id.hashCode.abs() % 900;
    final tz.TZDateTime when = _nextInstanceOf(reminder);
    if (when.isBefore(tz.TZDateTime.now(tz.local))) return;

    DateTimeComponents? components;
    switch (reminder.repeat) {
      case ReminderRepeat.daily:
        components = DateTimeComponents.time;
        break;
      case ReminderRepeat.weekly:
        components = DateTimeComponents.dayOfWeekAndTime;
        break;
      case ReminderRepeat.monthly:
        components = DateTimeComponents.dayOfMonthAndTime;
        break;
      case ReminderRepeat.none:
        components = null;
        break;
    }

    final NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: const BigTextStyleInformation(''),
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );

    try {
      await _plugin.zonedSchedule(
        id,
        reminder.title.isEmpty ? 'Lembrete do ZOOM' : reminder.title,
        reminder.message,
        when,
        details,
        androidScheduleMode: _exactAllowed
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: components,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      try {
        await _plugin.zonedSchedule(
          id,
          reminder.title,
          reminder.message,
          when,
          details,
          androidScheduleMode: AndroidScheduleMode.inexact,
          matchDateTimeComponents: components,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {}
    }
  }

  Future<void> scheduleAll(List<Reminder> reminders) async {
    await cancelAllAlarms();
    for (final Reminder r in reminders) {
      await scheduleReminder(r);
    }
  }

  Future<void> scheduleBackupReminder(int hour, int minute) async {
    await init();
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime when = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (when.isBefore(now)) {
      when = when.add(const Duration(days: 1));
    }
    try {
      await _plugin.zonedSchedule(
        NotificationIds.backupReminder,
        'Hora do backup!',
        'Faca uma copia dos seus dados do ZOOM e envie para o seu e-mail.',
        when,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'zoom_backup',
            'Backup',
            channelDescription: 'Lembrete para enviar backup por e-mail',
            importance: Importance.defaultImportance,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  Future<void> cancelBackupReminder() async {
    try {
      await _plugin.cancel(NotificationIds.backupReminder);
    } catch (_) {}
  }

  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  Future<void> cancelAllAlarms() async {
    try {
      final List<PendingNotificationRequest> pending =
          await _plugin.pendingNotificationRequests();
      for (final PendingNotificationRequest p in pending) {
        if (p.id != NotificationIds.backupReminder) {
          await _plugin.cancel(p.id);
        }
      }
    } catch (_) {}
  }

  Future<void> showNow(String title, String body) async {
    await init();
    try {
      await _plugin.show(
        0,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'zoom_geral',
            'Geral',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {}
  }

  bool get supported =>
      kIsWeb == false && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  tz.TZDateTime _nextInstanceOf(Reminder reminder) {
    final DateTime d = reminder.dateTime;
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      d.year,
      d.month,
      d.day,
      d.hour,
      d.minute,
    );
    switch (reminder.repeat) {
      case ReminderRepeat.none:
        break;
      case ReminderRepeat.daily:
        while (scheduled.isBefore(now)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }
        break;
      case ReminderRepeat.weekly:
        while (scheduled.isBefore(now)) {
          scheduled = scheduled.add(const Duration(days: 7));
        }
        break;
      case ReminderRepeat.monthly:
        while (scheduled.isBefore(now)) {
          scheduled = tz.TZDateTime(
            tz.local,
            scheduled.year,
            scheduled.month + 1,
            scheduled.day,
            scheduled.hour,
            scheduled.minute,
          );
        }
        break;
    }
    return scheduled;
  }
}
