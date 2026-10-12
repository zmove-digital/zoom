import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../data/models/reminder.dart';
import '../data/storage/local_database.dart';

typedef ReminderScheduler = Future<void> Function(List<Reminder> reminders);

class ReminderController extends ChangeNotifier {
  ReminderController(this._db) {
    reminders = _db.listOf(DbKeys.reminders).map(Reminder.fromJson).toList();
  }

  final LocalDatabase _db;
  late List<Reminder> reminders;
  ReminderScheduler? scheduler;

  List<Reminder> get upcoming {
    final List<Reminder> list = List<Reminder>.from(reminders)
      ..sort((Reminder a, Reminder b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  int get activeCount =>
      reminders.where((Reminder r) => r.enabled).length;

  void add(Reminder r) {
    reminders.add(r);
    _persist();
    notifyListeners();
    _reschedule();
  }

  void update(Reminder r) {
    final int index = reminders.indexWhere((Reminder e) => e.id == r.id);
    if (index >= 0) {
      reminders[index] = r;
      _persist();
      notifyListeners();
      _reschedule();
    }
  }

  void toggle(Reminder r, bool enabled) {
    update(r.copyWith(enabled: enabled));
  }

  void delete(String id) {
    reminders.removeWhere((Reminder r) => r.id == id);
    _persist();
    notifyListeners();
    _reschedule();
  }

  void replaceAll(List<Reminder> value) {
    reminders = value;
    _persist();
    notifyListeners();
    _reschedule();
  }

  Future<void> rescheduleAll() => _reschedule();

  Future<void> _reschedule() async {
    if (scheduler != null) {
      await scheduler!(reminders);
    }
  }

  void _persist() =>
      _db.setList(DbKeys.reminders, reminders.map((Reminder e) => e.toJson()).toList());

  void reload() {
    reminders =
        _db.listOf(DbKeys.reminders).map(Reminder.fromJson).toList();
    notifyListeners();
    _reschedule();
  }
}
