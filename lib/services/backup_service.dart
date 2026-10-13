import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants.dart';
import '../data/storage/local_database.dart';
import 'backup_crypto.dart';

enum RestoreOutcome { ok, needsPin, wrongPinOrCorrupted, invalid }

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

  Future<File> writeBackupFile({String? pin}) async {
    final Directory dir = await getTemporaryDirectory();
    final DateTime now = DateTime.now();
    final String stamp =
        '${now.year}${_two(now.month)}${_two(now.day)}_${_two(now.hour)}${_two(now.minute)}';
    final File file = File('${dir.path}${Platform.pathSeparator}zoom_backup_$stamp.json');
    final bool protect = pin != null && pin.isNotEmpty;
    final Map<String, dynamic> payload =
        protect ? BackupCrypto.encrypt(buildPayload(), pin) : buildPayload();
    final String encoded = const JsonEncoder.withIndent('  ').convert(payload);
    await file.writeAsString(encoded, flush: true);
    return file;
  }

  Future<void> shareBackup({String? email, String? pin}) async {
    final bool protect = pin != null && pin.isNotEmpty;
    final File file = await writeBackupFile(pin: pin);
    final String subject = 'Backup ZOOM - ${DateTime.now().toIso8601String().substring(0, 10)}';
    String body = email == null || email.isEmpty
        ? 'Segue o backup dos meus dados do ZOOM. Guarde este arquivo em local seguro.'
        : 'Segue o backup dos meus dados do ZOOM. Guarde este arquivo em local seguro.\n\nDica: envie para $email.';
    if (protect) {
      body = '$body\n\nEste arquivo está protegido pelo PIN do app. '
          'Para restaurar, informe o mesmo PIN.';
    }
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

  Future<String?> pickBackupRaw() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['json'],
    );
    final String? path = result?.files.single.path;
    if (path == null) return null;
    try {
      return await File(path).readAsString();
    } catch (_) {
      return null;
    }
  }

  Future<RestoreOutcome> restoreFromRaw(String raw, {String? pin}) async {
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return RestoreOutcome.invalid;
    }
    Map<String, dynamic> payload = decoded;
    if (BackupCrypto.isEncrypted(decoded)) {
      if (pin == null || pin.isEmpty) return RestoreOutcome.needsPin;
      final Map<String, dynamic>? plain = BackupCrypto.decrypt(decoded, pin);
      if (plain == null) return RestoreOutcome.wrongPinOrCorrupted;
      payload = plain;
    }
    final Object? data = payload['data'];
    if (data is! Map) return RestoreOutcome.invalid;
    try {
      _db.replaceAll(data.cast<String, dynamic>());
      await _db.flush();
    } catch (_) {
      return RestoreOutcome.invalid;
    }
    return RestoreOutcome.ok;
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
