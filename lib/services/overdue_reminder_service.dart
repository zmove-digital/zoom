import '../core/utils/formatters.dart';
import '../data/models/app_settings.dart';
import '../data/models/transaction.dart';
import '../state/finance_controller.dart';
import '../state/settings_controller.dart';
import 'notification_service.dart';

/// Mantém o aviso diário de lançamentos vencidos em sincronia com os dados.
///
/// Reagenda a notificação sempre que os lançamentos ou as preferências mudam,
/// listando os lançamentos vencidos e ainda não efetivados.
class OverdueReminderService {
  OverdueReminderService(this._finance, this._settings, this._notifications);

  final FinanceController _finance;
  final SettingsController _settings;
  final NotificationService _notifications;

  Future<void> sync() async {
    final AppSettings settings = _settings.settings;
    if (!settings.notificationsEnabled || !settings.overdueReminderEnabled) {
      await _notifications.cancelOverdueReminder();
      return;
    }

    final List<Transaction> overdue = _finance.overdueTransactions;
    if (overdue.isEmpty) {
      await _notifications.cancelOverdueReminder();
      return;
    }

    final String sym = _settings.currencySymbol;
    final List<String> lines = overdue.take(6).map((Transaction t) {
      final String label = t.description.trim().isEmpty
          ? (_finance.categoryById(t.categoryId)?.name ?? 'Lançamento')
          : t.description.trim();
      final String kind =
          t.type == TransactionType.income ? 'a receber' : 'a pagar';
      return '• $label — ${Money.format(t.amount, '', symbol: sym)} ($kind)';
    }).toList();
    if (overdue.length > lines.length) {
      lines.add('+ ${overdue.length - lines.length} lançamento(s)');
    }

    await _notifications.scheduleOverdueReminder(
      title: overdue.length == 1
          ? '1 lançamento vencido'
          : '${overdue.length} lançamentos vencidos',
      body: lines.join('\n'),
      hour: settings.overdueReminderHour,
      minute: settings.overdueReminderMinute,
    );
  }
}
