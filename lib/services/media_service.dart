import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class MediaService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickImage({bool fromCamera = false}) async {
    final XFile? picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return _copyToAppDir(File(picked.path), 'bg');
  }

  Future<String?> pickSound() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['mp3', 'wav', 'ogg', 'm4a', 'aac'],
    );
    if (result == null || result.files.single.path == null) return null;
    return _copyToAppDir(File(result.files.single.path!), 'snd');
  }

  Future<String?> _copyToAppDir(File source, String prefix) async {
    if (kIsWeb) return source.path;
    final Directory dir = await getApplicationSupportDirectory();
    final Directory media = Directory('${dir.path}${Platform.pathSeparator}media');
    if (!await media.exists()) {
      await media.create(recursive: true);
    }
    final String ext = source.path.split('.').last;
    final String name =
        '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final File dest = File('${media.path}${Platform.pathSeparator}$name');
    await source.copy(dest.path);
    return dest.path;
  }

  Future<void> deleteFile(String? path) async {
    if (path == null || path.isEmpty || kIsWeb) return;
    try {
      final File file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
