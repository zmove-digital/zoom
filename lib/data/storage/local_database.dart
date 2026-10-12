import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocalDatabase {
  LocalDatabase._(this._file, this._data);

  final File _file;
  Map<String, dynamic> _data;
  Future<void> _writeQueue = Future<void>.value();

  static const int schemaVersion = 1;

  static Future<LocalDatabase> open() async {
    final Directory dir = await getApplicationSupportDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final File file = File('${dir.path}${Platform.pathSeparator}grana_db.json');
    Map<String, dynamic> data = <String, dynamic>{};
    if (await file.exists()) {
      try {
        final String raw = await file.readAsString();
        if (raw.trim().isNotEmpty) {
          data = jsonDecode(raw) as Map<String, dynamic>;
        }
      } catch (_) {
        data = <String, dynamic>{};
      }
    }
    data.putIfAbsent('meta', () => <String, dynamic>{});
    (data['meta'] as Map<String, dynamic>)['schemaVersion'] = schemaVersion;
    return LocalDatabase._(file, data);
  }

  Map<String, dynamic> get raw => _data;

  List<Map<String, dynamic>> listOf(String key) {
    final Object? value = _data[key];
    if (value is List) {
      return value
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> e) => e.cast<String, dynamic>())
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  void setList(String key, List<Map<String, dynamic>> value) {
    _data[key] = value;
    scheduleSave();
  }

  Map<String, dynamic> mapOf(String key) {
    final Object? value = _data[key];
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  void setMap(String key, Map<String, dynamic> value) {
    _data[key] = value;
    scheduleSave();
  }

  void replaceAll(Map<String, dynamic> data) {
    _data = Map<String, dynamic>.from(data);
    scheduleSave();
  }

  Map<String, dynamic> snapshot() =>
      jsonDecode(jsonEncode(_data)) as Map<String, dynamic>;

  void scheduleSave() {
    _writeQueue = _writeQueue.then((_) => _save());
  }

  Future<void> flush() => _writeQueue;

  Future<void> _save() async {
    try {
      final String encoded = const JsonEncoder.withIndent('  ').convert(_data);
      final File temp = File('${_file.path}.tmp');
      await temp.writeAsString(encoded, flush: true);
      await temp.rename(_file.path);
    } catch (_) {
      // Falha silenciosa: os dados permanecem em memoria.
    }
  }
}
