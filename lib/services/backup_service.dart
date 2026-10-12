import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants.dart';
import '../data/storage/local_database.dart';

class BackupService {
  BackupService(this._db);

  final LocalDatabase _db;

  Map<String, dynamic> buildPayload() {
    return <String, dynamic>{
      'app': AppInfo.appName,
      'appVersion': AppInfo.version,
      'schemaVersion': LocalDatabase.schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': _db.snapshot(),
    };
  }

  Future<File> writeBackupFile() async {
    final Directory dir = await getTemporaryDirectory();
    final DateTime now = DateTime.now();
    final String stamp =
        '${now.year}${_two(now.month)}${_two(now.day)}_${_two(now.hour)}${_two(now.minute)}';
    final File file = File('${dir.path}${Platform.pathSeparator}zoom_backup_$stamp.json');
    final String encoded =
        const JsonEncoder.withIndent('  ').convert(buildPayload());
    await file.writeAsString(encoded, flush: true);
    return file;
  }

  Future<void> shareBackup({String? email}) async {
    final File file = await writeBackupFile();
    final String subject = 'Backup ZOOM - ${DateTime.now().toIso8601String().substring(0, 10)}';
    final String body = email == null || email.isEmpty
        ? 'Segue o backup dos meus dados do ZOOM. Guarde este arquivo em local seguro.'
        : 'Segue o backup dos meus dados do ZOOM. Guarde este arquivo em local seguro.\n\nDica: envie para $email.';
    try {
      await Share.shareXFiles(
        <XFile>[XFile(file.path, mimeType: 'application/json')],
        subject: subject,
        text: body,
      );
    } catch (_) {
      await Share.share(body, subject: subject);
    }
  }

  Future<bool> restoreFromPickedFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['json'],
    );
    if (result == null || result.files.single.path == null) return false;
    try {
      final String raw = await File(result.files.single.path!).readAsString();
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>;
      final Object? data = decoded['data'];
      if (data is! Map) return false;
      _db.replaceAll(data.cast<String, dynamic>());
      await _db.flush();
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
