import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../data/models/app_settings.dart';
import '../data/storage/local_database.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._db) {
    final Map<String, dynamic> stored = _db.mapOf(DbKeys.settings);
    settings =
        stored.isEmpty ? AppSettings() : AppSettings.fromJson(stored);
  }

  final LocalDatabase _db;
  late AppSettings settings;

  String get currencySymbol =>
      kCurrencySymbols[settings.currencyCode] ?? settings.currencyCode;

  ThemeMode get themeMode {
    switch (settings.themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  void update(AppSettings Function(AppSettings) mutate) {
    settings = mutate(settings);
    _db.setMap(DbKeys.settings, settings.toJson());
    notifyListeners();
  }

  void completeOnboarding({
    required String name,
    required String currencyCode,
    required String backupEmail,
  }) {
    update(
      (AppSettings s) => s.copyWith(
        onboardingDone: true,
        userName: name.trim(),
        currencyCode: currencyCode,
        backupEmail: backupEmail.trim(),
      ),
    );
  }

  void setThemeMode(AppThemeMode mode) =>
      update((AppSettings s) => s.copyWith(themeMode: mode));

  void setSeedColor(String hex) =>
      update((AppSettings s) => s.copyWith(seedColorHex: hex));

  void setAccentColor(String hex) =>
      update((AppSettings s) => s.copyWith(accentColorHex: hex));

  void setBackgroundImage(String? path) =>
      update((AppSettings s) => s.copyWith(backgroundImagePath: path));

  void setBackgroundOpacity(double value) =>
      update((AppSettings s) => s.copyWith(backgroundOpacity: value));

  void setCardOpacity(double value) =>
      update((AppSettings s) => s.copyWith(cardOpacity: value));

  void setFontScale(double value) =>
      update((AppSettings s) => s.copyWith(fontScale: value));

  void setRoundedCards(bool value) =>
      update((AppSettings s) => s.copyWith(useRoundedCards: value));

  void setSoundEnabled(bool value) =>
      update((AppSettings s) => s.copyWith(soundEnabled: value));

  void setTapSound(String? path) =>
      update((AppSettings s) => s.copyWith(tapSoundPath: path));

  void setNotificationSound(String? path) =>
      update((AppSettings s) => s.copyWith(notificationSoundPath: path));

  void setHaptics(bool value) =>
      update((AppSettings s) => s.copyWith(hapticsEnabled: value));

  void setNotificationsEnabled(bool value) =>
      update((AppSettings s) => s.copyWith(notificationsEnabled: value));

  void setBackupEmail(String email) =>
      update((AppSettings s) => s.copyWith(backupEmail: email.trim()));

  void setBackupReminder({bool? enabled, int? hour, int? minute}) => update(
        (AppSettings s) => s.copyWith(
          backupReminderEnabled: enabled,
          backupReminderHour: hour,
          backupReminderMinute: minute,
        ),
      );

  void markBackupDone() =>
      update((AppSettings s) => s.copyWith(lastBackupAt: DateTime.now()));

  void setPin({required bool enabled, String? pin}) => update(
        (AppSettings s) => s.copyWith(
          pinEnabled: enabled,
          pin: pin,
          pinAttempts: 0,
          pinLockedUntil: null,
        ),
      );

  bool get pinLocked {
    final DateTime? until = settings.pinLockedUntil;
    return until != null && until.isAfter(DateTime.now());
  }

  Duration get pinLockRemaining {
    final DateTime? until = settings.pinLockedUntil;
    if (until == null) return Duration.zero;
    final Duration remaining = until.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void registerFailedPinAttempt() {
    final int next = settings.pinAttempts + 1;
    if (next >= SecurityRules.maxPinAttempts) {
      update((AppSettings s) => s.copyWith(
            pinAttempts: 0,
            pinLockedUntil: DateTime.now().add(SecurityRules.pinLockout),
          ));
    } else {
      update((AppSettings s) => s.copyWith(pinAttempts: next));
    }
  }

  void clearPinAttempts() => update(
        (AppSettings s) => s.copyWith(pinAttempts: 0, pinLockedUntil: null),
      );

  void setCurrency(String code) =>
      update((AppSettings s) => s.copyWith(currencyCode: code));

  void setUserName(String name) =>
      update((AppSettings s) => s.copyWith(userName: name.trim()));

  void setHideBalance(bool value) =>
      update((AppSettings s) => s.copyWith(hideBalance: value));

  void reload() {
    final Map<String, dynamic> stored = _db.mapOf(DbKeys.settings);
    settings = stored.isEmpty ? AppSettings() : AppSettings.fromJson(stored);
    notifyListeners();
  }
}
