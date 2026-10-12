import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/utils/formatters.dart';
import '../core/utils/id_generator.dart';
import '../data/models/agenda_entry.dart';
import '../data/storage/local_database.dart';

class AgendaController extends ChangeNotifier {
  AgendaController(this._db) {
    entries = _db.listOf(DbKeys.agenda).map(AgendaEntry.fromJson).toList();
  }

  final LocalDatabase _db;
  late List<AgendaEntry> entries;

  List<AgendaEntry> sorted({bool desc = true}) {
    final List<AgendaEntry> list = List<AgendaEntry>.from(entries)
      ..sort((AgendaEntry a, AgendaEntry b) => desc
          ? b.date.compareTo(a.date)
          : a.date.compareTo(b.date));
    return list;
  }

  List<AgendaEntry> search(String query) {
    if (query.trim().isEmpty) return sorted();
    final String q = query.toLowerCase();
    return entries
        .where((AgendaEntry e) =>
            e.title.toLowerCase().contains(q) ||
            e.content.toLowerCase().contains(q) ||
            e.tags.any((String t) => t.toLowerCase().contains(q)))
        .toList()
      ..sort((AgendaEntry a, AgendaEntry b) => b.date.compareTo(a.date));
  }

  List<AgendaEntry> onDay(DateTime day) {
    return entries
        .where((AgendaEntry e) => DateHelpers.isSameDay(e.date, day))
        .toList()
      ..sort((AgendaEntry a, AgendaEntry b) => b.updatedAt.compareTo(a.updatedAt));
  }

  AgendaEntry? byId(String id) {
    for (final AgendaEntry e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  int get thisMonthCount {
    final DateTime now = DateTime.now();
    return entries
        .where((AgendaEntry e) => DateHelpers.isSameMonth(e.date, now))
        .length;
  }

  int get streak {
    int count = 0;
    DateTime day = DateHelpers.startOfDay(DateTime.now());
    while (onDay(day).isNotEmpty) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  void add(AgendaEntry entry) {
    entries.add(entry);
    _persist();
    notifyListeners();
  }

  void update(AgendaEntry entry) {
    final int index = entries.indexWhere((AgendaEntry e) => e.id == entry.id);
    if (index >= 0) {
      entries[index] = entry;
      _persist();
      notifyListeners();
    }
  }

  void delete(String id) {
    entries.removeWhere((AgendaEntry e) => e.id == id);
    _persist();
    notifyListeners();
  }

  void replaceAll(List<AgendaEntry> value) {
    entries = value;
    _persist();
    notifyListeners();
  }

  AgendaEntry blankFor(DateTime day) => AgendaEntry(id: newId(), date: day);

  void _persist() =>
      _db.setList(DbKeys.agenda, entries.map((AgendaEntry e) => e.toJson()).toList());

  void reload() {
    entries = _db.listOf(DbKeys.agenda).map(AgendaEntry.fromJson).toList();
    notifyListeners();
  }
}
