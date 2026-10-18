enum AppThemeMode { system, light, dark }

AppThemeMode appThemeModeFromName(String? name) {
  return AppThemeMode.values.firstWhere(
    (AppThemeMode m) => m.name == name,
    orElse: () => AppThemeMode.system,
  );
}

class AppSettings {
  AppSettings({
    this.onboardingDone = false,
    this.userName = '',
    this.currencyCode = 'BRL',
    this.themeMode = AppThemeMode.system,
    this.seedColorHex = '6C5CE7',
    this.accentColorHex = '00B894',
    this.backgroundImagePath,
    this.backgroundOpacity = 0.12,
    this.cardOpacity = 1.0,
    this.fontScale = 1.0,
    this.useRoundedCards = true,
    this.soundEnabled = true,
    this.tapSoundPath,
    this.notificationSoundPath,
    this.hapticsEnabled = true,
    this.notificationsEnabled = true,
    this.backupEmail = '',
    this.backupReminderEnabled = false,
    this.backupReminderHour = 20,
    this.backupReminderMinute = 0,
    this.overdueReminderEnabled = true,
    this.overdueReminderHour = 9,
    this.overdueReminderMinute = 0,
    this.lastBackupAt,
    this.pinEnabled = false,
    this.pin = '',
    this.pinAttempts = 0,
    this.pinLockedUntil,
    this.hideBalance = false,
  });

  bool onboardingDone;
  String userName;
  String currencyCode;
  AppThemeMode themeMode;
  String seedColorHex;
  String accentColorHex;
  String? backgroundImagePath;
  double backgroundOpacity;
  double cardOpacity;
  double fontScale;
  bool useRoundedCards;
  bool soundEnabled;
  String? tapSoundPath;
  String? notificationSoundPath;
  bool hapticsEnabled;
  bool notificationsEnabled;
  String backupEmail;
  bool backupReminderEnabled;
  int backupReminderHour;
  int backupReminderMinute;
  bool overdueReminderEnabled;
  int overdueReminderHour;
  int overdueReminderMinute;
  DateTime? lastBackupAt;
  bool pinEnabled;
  String pin;
  int pinAttempts;
  DateTime? pinLockedUntil;
  bool hideBalance;

  AppSettings copyWith({
    bool? onboardingDone,
    String? userName,
    String? currencyCode,
    AppThemeMode? themeMode,
    String? seedColorHex,
    String? accentColorHex,
    Object? backgroundImagePath = _unset,
    double? backgroundOpacity,
    double? cardOpacity,
    double? fontScale,
    bool? useRoundedCards,
    bool? soundEnabled,
    Object? tapSoundPath = _unset,
    Object? notificationSoundPath = _unset,
    bool? hapticsEnabled,
    bool? notificationsEnabled,
    String? backupEmail,
    bool? backupReminderEnabled,
    int? backupReminderHour,
    int? backupReminderMinute,
    bool? overdueReminderEnabled,
    int? overdueReminderHour,
    int? overdueReminderMinute,
    Object? lastBackupAt = _unset,
    bool? pinEnabled,
    String? pin,
    int? pinAttempts,
    Object? pinLockedUntil = _unset,
    bool? hideBalance,
  }) {
    return AppSettings(
      onboardingDone: onboardingDone ?? this.onboardingDone,
      userName: userName ?? this.userName,
      currencyCode: currencyCode ?? this.currencyCode,
      themeMode: themeMode ?? this.themeMode,
      seedColorHex: seedColorHex ?? this.seedColorHex,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      backgroundImagePath: backgroundImagePath == _unset
          ? this.backgroundImagePath
          : backgroundImagePath as String?,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      cardOpacity: cardOpacity ?? this.cardOpacity,
      fontScale: fontScale ?? this.fontScale,
      useRoundedCards: useRoundedCards ?? this.useRoundedCards,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      tapSoundPath:
          tapSoundPath == _unset ? this.tapSoundPath : tapSoundPath as String?,
      notificationSoundPath: notificationSoundPath == _unset
          ? this.notificationSoundPath
          : notificationSoundPath as String?,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      backupEmail: backupEmail ?? this.backupEmail,
      backupReminderEnabled:
          backupReminderEnabled ?? this.backupReminderEnabled,
      backupReminderHour: backupReminderHour ?? this.backupReminderHour,
      backupReminderMinute: backupReminderMinute ?? this.backupReminderMinute,
      overdueReminderEnabled:
          overdueReminderEnabled ?? this.overdueReminderEnabled,
      overdueReminderHour: overdueReminderHour ?? this.overdueReminderHour,
      overdueReminderMinute:
          overdueReminderMinute ?? this.overdueReminderMinute,
      lastBackupAt:
          lastBackupAt == _unset ? this.lastBackupAt : lastBackupAt as DateTime?,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      pin: pin ?? this.pin,
      pinAttempts: pinAttempts ?? this.pinAttempts,
      pinLockedUntil: pinLockedUntil == _unset
          ? this.pinLockedUntil
          : pinLockedUntil as DateTime?,
      hideBalance: hideBalance ?? this.hideBalance,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'onboardingDone': onboardingDone,
        'userName': userName,
        'currencyCode': currencyCode,
        'themeMode': themeMode.name,
        'seedColorHex': seedColorHex,
        'accentColorHex': accentColorHex,
        'backgroundImagePath': backgroundImagePath,
        'backgroundOpacity': backgroundOpacity,
        'cardOpacity': cardOpacity,
        'fontScale': fontScale,
        'useRoundedCards': useRoundedCards,
        'soundEnabled': soundEnabled,
        'tapSoundPath': tapSoundPath,
        'notificationSoundPath': notificationSoundPath,
        'hapticsEnabled': hapticsEnabled,
        'notificationsEnabled': notificationsEnabled,
        'backupEmail': backupEmail,
        'backupReminderEnabled': backupReminderEnabled,
        'backupReminderHour': backupReminderHour,
        'backupReminderMinute': backupReminderMinute,
        'overdueReminderEnabled': overdueReminderEnabled,
        'overdueReminderHour': overdueReminderHour,
        'overdueReminderMinute': overdueReminderMinute,
        'lastBackupAt': lastBackupAt?.toIso8601String(),
        'pinEnabled': pinEnabled,
        'pin': pin,
        'pinAttempts': pinAttempts,
        'pinLockedUntil': pinLockedUntil?.toIso8601String(),
        'hideBalance': hideBalance,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        onboardingDone: json['onboardingDone'] as bool? ?? false,
        userName: json['userName'] as String? ?? '',
        currencyCode: json['currencyCode'] as String? ?? 'BRL',
        themeMode: appThemeModeFromName(json['themeMode'] as String?),
        seedColorHex: json['seedColorHex'] as String? ?? '6C5CE7',
        accentColorHex: json['accentColorHex'] as String? ?? '00B894',
        backgroundImagePath: json['backgroundImagePath'] as String?,
        backgroundOpacity: (json['backgroundOpacity'] as num?)?.toDouble() ?? 0.12,
        cardOpacity: (json['cardOpacity'] as num?)?.toDouble() ?? 1.0,
        fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
        useRoundedCards: json['useRoundedCards'] as bool? ?? true,
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        tapSoundPath: json['tapSoundPath'] as String?,
        notificationSoundPath: json['notificationSoundPath'] as String?,
        hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        backupEmail: json['backupEmail'] as String? ?? '',
        backupReminderEnabled: json['backupReminderEnabled'] as bool? ?? false,
        backupReminderHour: (json['backupReminderHour'] as num?)?.toInt() ?? 20,
        backupReminderMinute:
            (json['backupReminderMinute'] as num?)?.toInt() ?? 0,
        overdueReminderEnabled:
            json['overdueReminderEnabled'] as bool? ?? true,
        overdueReminderHour:
            (json['overdueReminderHour'] as num?)?.toInt() ?? 9,
        overdueReminderMinute:
            (json['overdueReminderMinute'] as num?)?.toInt() ?? 0,
        lastBackupAt: json['lastBackupAt'] == null
            ? null
            : DateTime.parse(json['lastBackupAt'] as String),
        pinEnabled: json['pinEnabled'] as bool? ?? false,
        pin: json['pin'] as String? ?? '',
        pinAttempts: (json['pinAttempts'] as num?)?.toInt() ?? 0,
        pinLockedUntil: json['pinLockedUntil'] == null
            ? null
            : DateTime.parse(json['pinLockedUntil'] as String),
        hideBalance: json['hideBalance'] as bool? ?? false,
      );
}

const Object _unset = Object();
