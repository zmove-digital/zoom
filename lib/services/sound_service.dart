import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SoundService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playTap({String? path, bool enabled = true, bool haptics = true}) async {
    if (haptics) {
      await HapticFeedback.selectionClick();
    }
    if (!enabled) return;
    if (path != null && path.isNotEmpty && !kIsWeb) {
      await playFile(path);
      return;
    }
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> playFile(String path) async {
    try {
      if (kIsWeb) return;
      final File file = File(path);
      if (!await file.exists()) return;
      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (_) {}
  }

  Future<void> playAsset(String assetPath) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (_) {}
  }

  void dispose() {
    _player.dispose();
  }
}
