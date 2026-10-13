import 'package:flutter/material.dart';

class AppInfo {
  static const String appName = 'ZOOM';
  static const String tagline = 'Seu dinheiro, do seu jeito';
  static const String version = '1.0.0';
}

class SecurityRules {
  static const int pinLength = 4;
  static const int maxPinAttempts = 6;
  static const Duration pinLockout = Duration(minutes: 15);
}

class DbKeys {
  static const String transactions = 'transactions';
  static const String categories = 'categories';
  static const String agenda = 'agenda';
  static const String reminders = 'reminders';
  static const String budgets = 'budgets';
  static const String goals = 'goals';
  static const String settings = 'settings';
  static const String meta = 'meta';
}

class NotificationIds {
  static const int backupReminder = 1000;
  static const int alarmBase = 2000;
}

const List<String> kCurrencyOptions = <String>[
  'BRL',
  'USD',
  'EUR',
  'GBP',
  'ARS',
  'MXN',
  'JPY',
];

const Map<String, String> kCurrencySymbols = <String, String>{
  'BRL': r'R$',
  'USD': r'$',
  'EUR': '€',
  'GBP': '£',
  'ARS': r'$',
  'MXN': r'$',
  'JPY': '¥',
};

const List<int> kCategoryIconChoices = <int>[
  0xe59c,
  0xe7fd,
  0xe8a1,
  0xe56b,
  0xe531,
  0xe54c,
  0xe1d5,
  0xe571,
  0xe7f4,
  0xe1b1,
  0xe8f7,
  0xe3b0,
  0xe0b0,
  0xe6c3,
  0xe30a,
  0xe4bd,
  0xe7e9,
  0xe88a,
  0xe37c,
  0xf05a2,
  0xe6e7,
  0xe5c6,
  0xe13d,
  0xe2f2,
];

const Map<int, IconData> kIconsByCodePoint = <int, IconData>{
  0xe59c: IconData(0xe59c, fontFamily: 'MaterialIcons'),
  0xe7fd: IconData(0xe7fd, fontFamily: 'MaterialIcons'),
  0xe8a1: IconData(0xe8a1, fontFamily: 'MaterialIcons'),
  0xe56b: IconData(0xe56b, fontFamily: 'MaterialIcons'),
  0xe531: IconData(0xe531, fontFamily: 'MaterialIcons'),
  0xe54c: IconData(0xe54c, fontFamily: 'MaterialIcons'),
  0xe1d5: IconData(0xe1d5, fontFamily: 'MaterialIcons'),
  0xe571: IconData(0xe571, fontFamily: 'MaterialIcons'),
  0xe7f4: IconData(0xe7f4, fontFamily: 'MaterialIcons'),
  0xe1b1: IconData(0xe1b1, fontFamily: 'MaterialIcons'),
  0xe8f7: IconData(0xe8f7, fontFamily: 'MaterialIcons'),
  0xe3b0: IconData(0xe3b0, fontFamily: 'MaterialIcons'),
  0xe0b0: IconData(0xe0b0, fontFamily: 'MaterialIcons'),
  0xe6c3: IconData(0xe6c3, fontFamily: 'MaterialIcons'),
  0xe30a: IconData(0xe30a, fontFamily: 'MaterialIcons'),
  0xe4bd: IconData(0xe4bd, fontFamily: 'MaterialIcons'),
  0xe7e9: IconData(0xe7e9, fontFamily: 'MaterialIcons'),
  0xe88a: IconData(0xe88a, fontFamily: 'MaterialIcons'),
  0xe37c: IconData(0xe37c, fontFamily: 'MaterialIcons'),
  0xf05a2: IconData(0xf05a2, fontFamily: 'MaterialIcons'),
  0xe6e7: IconData(0xe6e7, fontFamily: 'MaterialIcons'),
  0xe5c6: IconData(0xe5c6, fontFamily: 'MaterialIcons'),
  0xe13d: IconData(0xe13d, fontFamily: 'MaterialIcons'),
  0xe2f2: IconData(0xe2f2, fontFamily: 'MaterialIcons'),
  0xe263: IconData(0xe263, fontFamily: 'MaterialIcons'),
  0xe53d: IconData(0xe53d, fontFamily: 'MaterialIcons'),
  0xe530: IconData(0xe530, fontFamily: 'MaterialIcons'),
  0xe501: IconData(0xe501, fontFamily: 'MaterialIcons'),
  0xe265: IconData(0xe265, fontFamily: 'MaterialIcons'),
  0xe8b6: IconData(0xe8b6, fontFamily: 'MaterialIcons'),
  0xe5d3: IconData(0xe5d3, fontFamily: 'MaterialIcons'),
};

const List<String> kPaletteHex = <String>[
  'FF6B6B',
  'FFD166',
  '06D6A0',
  '4ECDC4',
  '457B9D',
  'A06CD5',
  'F78FB3',
  'F8961E',
  '43AA8B',
  '577590',
  'EF476F',
  '118AB2',
];

const Color kDefaultSeed = Color(0xFF6C5CE7);

const List<Color> kHeroGradient = <Color>[
  Color(0xFF8B5CF6),
  Color(0xFF6D28D9),
  Color(0xFF4C1D95),
];
