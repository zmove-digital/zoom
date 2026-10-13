import 'package:intl/intl.dart';

class Money {
  static String format(double value, String currencyCode, {String symbol = ''}) {
    final NumberFormat formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: symbol.isEmpty ? '' : '$symbol ',
      decimalDigits: 2,
    );
    return formatter.format(value).trim();
  }

  static String compact(double value, String symbol, {bool space = true}) {
    final String prefix = space ? '$symbol ' : symbol;
    final double abs = value.abs();
    if (abs >= 1000000) {
      return '$prefix${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (abs >= 1000) {
      return '$prefix${(value / 1000).toStringAsFixed(1)}k';
    }
    return '$prefix${value.toStringAsFixed(2)}';
  }

  static double parse(String raw) {
    String s = raw.trim().replaceAll(RegExp(r'[^0-9,.\-]'), '');
    final bool hasComma = s.contains(',');
    final bool hasDot = s.contains('.');
    if (hasComma && hasDot) {
      // pt-BR: "1.234,56" -> ponto é milhar, vírgula é decimal.
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else if (hasComma) {
      s = s.replaceAll(',', '.');
    }
    return double.tryParse(s) ?? 0;
  }

  static double round2(double value) => (value * 100).roundToDouble() / 100;
}

class DateHelpers {
  static final DateFormat dayMonth = DateFormat('dd/MM');
  static final DateFormat full = DateFormat('dd/MM/yyyy');
  static final DateFormat monthYear = DateFormat('MMMM yyyy', 'pt_BR');
  static final DateFormat monthShort = DateFormat('MMM', 'pt_BR');
  static final DateFormat time = DateFormat('HH:mm');
  static final DateFormat dateTime = DateFormat('dd/MM/yyyy HH:mm');

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month);
  static DateTime endOfMonth(DateTime d) => DateTime(d.year, d.month + 1, 0);
  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static int daysInMonth(DateTime d) => endOfMonth(d).day;

  static String weekdayLabel(DateTime d) {
    const List<String> labels = <String>[
      'seg',
      'ter',
      'qua',
      'qui',
      'sex',
      'sab',
      'dom',
    ];
    return labels[(d.weekday - 1).clamp(0, 6)];
  }
}
