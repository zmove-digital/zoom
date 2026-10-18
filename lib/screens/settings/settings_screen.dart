import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'
    hide colorFromHex, colorToHex;
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/category.dart';
import '../../services/backup_service.dart';
import '../../services/media_service.dart';
import '../../services/notification_service.dart';
import '../../services/overdue_reminder_service.dart';
import '../../services/sound_service.dart';
import '../../state/agenda_controller.dart';
import '../../state/finance_controller.dart';
import '../../state/reminder_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_scaffold.dart';
import '../reminders/reminders_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Ajustes',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: const <Widget>[
          _ProfileSection(),
          SizedBox(height: 16),
          _AppearanceSection(),
          SizedBox(height: 16),
          _SoundSection(),
          SizedBox(height: 16),
          _NotificationSection(),
          SizedBox(height: 16),
          _BackupSection(),
          SizedBox(height: 16),
          _PrivacySection(),
          SizedBox(height: 16),
          _AboutSection(),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.icon});
  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
          ],
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection();

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle('Perfil', icon: Icons.person_outline),
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Seu nome'),
                subtitle: Text(settings.settings.userName.isEmpty
                    ? 'Não definido'
                    : settings.settings.userName),
                onTap: () async {
                  final TextEditingController c = TextEditingController(
                      text: settings.settings.userName);
                  final String? value = await _textDialog(
                      context, 'Seu nome', c);
                  if (value != null) settings.setUserName(value);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Moeda'),
                subtitle: Text(settings.settings.currencyCode),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final String? code = await showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => SimpleDialog(
                      title: const Text('Escolha a moeda'),
                      children: kCurrencyOptions
                          .map(
                            (String c) => SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, c),
                              child: Text('$c (${kCurrencySymbols[c]})'),
                            ),
                          )
                          .toList(),
                    ),
                  );
                  if (code != null) settings.setCurrency(code);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    final MediaService media = context.read<MediaService>();
    final String? bg = settings.settings.backgroundImagePath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle('Aparência', icon: Icons.palette_outlined),
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: const Text('Tema'),
                subtitle: Text(_themeLabel(settings.settings.themeMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final AppThemeMode? mode = await showModalBottomSheet<AppThemeMode>(
                    context: context,
                    builder: (BuildContext context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: AppThemeMode.values
                            .map(
                              (AppThemeMode m) => ListTile(
                                title: Text(_themeLabel(m)),
                                onTap: () => Navigator.pop(context, m),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  );
                  if (mode != null) settings.setThemeMode(mode);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.color_lens_outlined),
                title: const Text('Cor principal'),
                trailing: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorFromHex(settings.settings.seedColorHex),
                    shape: BoxShape.circle,
                  ),
                ),
                onTap: () => _pickColor(
                  context,
                  colorFromHex(settings.settings.seedColorHex),
                  settings.setSeedColor,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.gradient_outlined),
                title: const Text('Cor de destaque'),
                trailing: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorFromHex(settings.settings.accentColorHex),
                    shape: BoxShape.circle,
                  ),
                ),
                onTap: () => _pickColor(
                  context,
                  colorFromHex(settings.settings.accentColorHex),
                  settings.setAccentColor,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.wallpaper_outlined),
                title: const Text('Imagem de fundo'),
                subtitle: Text(bg == null || bg.isEmpty
                    ? 'Sem imagem'
                    : bg.split(RegExp(r'[\\/]')).last),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (bg != null && bg.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          media.deleteFile(bg);
                          settings.setBackgroundImage(null);
                        },
                      ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () async {
                  final String? path = await media.pickImage();
                  if (path != null) settings.setBackgroundImage(path);
                },
              ),
              if (bg != null && bg.isNotEmpty) ...<Widget>[
                const Divider(height: 1),
                _sliderTile(
                  context,
                  'Intensidade do fundo',
                  settings.settings.backgroundOpacity,
                  0.05,
                  0.6,
                  (double v) => settings.setBackgroundOpacity(v),
                ),
              ],
              const Divider(height: 1),
              _sliderTile(
                context,
                'Opacidade dos cards',
                settings.settings.cardOpacity,
                0.5,
                1.0,
                (double v) => settings.setCardOpacity(v),
              ),
              const Divider(height: 1),
              _sliderTile(
                context,
                'Tamanho da fonte',
                settings.settings.fontScale,
                0.9,
                1.4,
                (double v) => settings.setFontScale(v),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.rounded_corner),
                title: const Text('Cards arredondados'),
                value: settings.settings.useRoundedCards,
                onChanged: settings.setRoundedCards,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _themeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'Seguir o sistema';
      case AppThemeMode.light:
        return 'Claro';
      case AppThemeMode.dark:
        return 'Escuro';
    }
  }
}

class _SoundSection extends StatelessWidget {
  const _SoundSection();

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    final SoundService sound = context.read<SoundService>();
    final MediaService media = context.read<MediaService>();
    final String? tap = settings.settings.tapSoundPath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle('Sons e vibração', icon: Icons.volume_up_outlined),
        Card(
          child: Column(
            children: <Widget>[
              SwitchListTile(
                secondary: const Icon(Icons.music_note_outlined),
                title: const Text('Sons do app'),
                value: settings.settings.soundEnabled,
                onChanged: settings.setSoundEnabled,
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.vibration),
                title: const Text('Vibrar ao tocar'),
                value: settings.settings.hapticsEnabled,
                onChanged: settings.setHaptics,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.touch_app_outlined),
                title: const Text('Som de toque'),
                subtitle: Text(tap == null
                    ? 'Padrão do sistema'
                    : tap.split(RegExp(r'[\\/]')).last),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () => sound.playTap(
                        path: tap,
                        enabled: true,
                        haptics: false,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.folder_open),
                      onPressed: () async {
                        final String? path = await media.pickSound();
                        if (path != null) settings.setTapSound(path);
                      },
                    ),
                    if (tap != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => settings.setTapSound(null),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationSection extends StatelessWidget {
  const _NotificationSection();

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    final NotificationService notifications = context.read<NotificationService>();
    final OverdueReminderService overdue =
        context.read<OverdueReminderService>();
    final MediaService media = context.read<MediaService>();
    final String? sound = settings.settings.notificationSoundPath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle('Notificações', icon: Icons.notifications_outlined),
        Card(
          child: Column(
            children: <Widget>[
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active_outlined),
                title: const Text('Ativar notificações'),
                subtitle: const Text('Lembretes, alarmes e avisos'),
                value: settings.settings.notificationsEnabled,
                onChanged: (bool v) async {
                  settings.setNotificationsEnabled(v);
                  if (v) await notifications.requestPermissions();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.music_note),
                title: const Text('Som de notificação'),
                subtitle: Text(sound == null
                    ? 'Padrão do sistema'
                    : sound.split(RegExp(r'[\\/]')).last),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () => sound == null
                          ? null
                          : context.read<SoundService>().playFile(sound),
                    ),
                    IconButton(
                      icon: const Icon(Icons.folder_open),
                      onPressed: () async {
                        final String? path = await media.pickSound();
                        if (path != null) settings.setNotificationSound(path);
                      },
                    ),
                    if (sound != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => settings.setNotificationSound(null),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.alarm),
                title: const Text('Gerenciar lembretes'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const RemindersScreen()),
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.error_outline),
                title: const Text('Avisar lançamentos vencidos'),
                subtitle: Text(
                  settings.settings.overdueReminderEnabled
                      ? 'Todo dia às ${settings.settings.overdueReminderHour.toString().padLeft(2, '0')}:${settings.settings.overdueReminderMinute.toString().padLeft(2, '0')}'
                      : 'Desativado',
                ),
                value: settings.settings.overdueReminderEnabled,
                onChanged: (bool v) async {
                  settings.setOverdueReminder(enabled: v);
                  if (v) await notifications.requestPermissions();
                  await overdue.sync();
                },
              ),
              if (settings.settings.overdueReminderEnabled) ...<Widget>[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Horário do aviso de vencidos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final TimeOfDay? t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: settings.settings.overdueReminderHour,
                        minute: settings.settings.overdueReminderMinute,
                      ),
                    );
                    if (t != null) {
                      settings.setOverdueReminder(
                          hour: t.hour, minute: t.minute);
                      await overdue.sync();
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BackupSection extends StatelessWidget {
  const _BackupSection();

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    final BackupService backup = context.read<BackupService>();
    final NotificationService notifications =
        context.read<NotificationService>();
    final FinanceController finance = context.read<FinanceController>();
    final AgendaController agenda = context.read<AgendaController>();
    final ReminderController reminders = context.read<ReminderController>();
    final DateTime? last = settings.settings.lastBackupAt;
    final bool protectBackup =
        settings.settings.pinEnabled && settings.settings.pin.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle('Backup dos dados', icon: Icons.backup_outlined),
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('E-mail para backup'),
                subtitle: Text(settings.settings.backupEmail.isEmpty
                    ? 'Não definido'
                    : settings.settings.backupEmail),
                onTap: () async {
                  final TextEditingController c = TextEditingController(
                      text: settings.settings.backupEmail);
                  final String? value = await _textDialog(
                      context, 'E-mail para backup', c,
                      keyboard: TextInputType.emailAddress);
                  if (value != null) settings.setBackupEmail(value);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('Enviar backup agora'),
                isThreeLine: true,
                subtitle: Text(
                  <String>[
                    'E-mail, WhatsApp ou Google Drive',
                    last == null
                        ? 'Nunca enviado'
                        : 'Último: ${DateHelpers.dateTime.format(last)}',
                    if (protectBackup) 'protegido pelo PIN',
                  ].join(' • '),
                ),
                onTap: () async {
                  final String? destination =
                      await _pickBackupDestination(context);
                  if (destination == null) return;
                  await backup.shareBackup(
                    email: destination == 'E-mail'
                        ? settings.settings.backupEmail
                        : null,
                    pin: protectBackup ? settings.settings.pin : null,
                    destination: destination,
                  );
                  settings.markBackupDone();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.restore_outlined),
                title: const Text('Restaurar de um arquivo'),
                subtitle: const Text('Substitui os dados atuais'),
                onTap: () => _restore(context, backup, settings, finance,
                    agenda, reminders),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.schedule_send_outlined),
                title: const Text('Lembrar de fazer backup'),
                subtitle: Text(
                  'Todo dia às ${settings.settings.backupReminderHour.toString().padLeft(2, '0')}:${settings.settings.backupReminderMinute.toString().padLeft(2, '0')}',
                ),
                value: settings.settings.backupReminderEnabled,
                onChanged: (bool v) async {
                  settings.setBackupReminder(enabled: v);
                  if (v) {
                    await notifications.scheduleBackupReminder(
                      settings.settings.backupReminderHour,
                      settings.settings.backupReminderMinute,
                    );
                  } else {
                    await notifications.cancelBackupReminder();
                  }
                },
              ),
              if (settings.settings.backupReminderEnabled) ...<Widget>[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Horário do lembrete'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final TimeOfDay? t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: settings.settings.backupReminderHour,
                        minute: settings.settings.backupReminderMinute,
                      ),
                    );
                    if (t != null) {
                      settings.setBackupReminder(
                          hour: t.hour, minute: t.minute);
                      await notifications.scheduleBackupReminder(
                          t.hour, t.minute);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<String?> _pickBackupDestination(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Enviar backup por',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('E-mail'),
              onTap: () => Navigator.pop(ctx, 'E-mail'),
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('WhatsApp'),
              onTap: () => Navigator.pop(ctx, 'WhatsApp'),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: const Text('Google Drive'),
              onTap: () => Navigator.pop(ctx, 'Google Drive'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _restore(
    BuildContext context,
    BackupService backup,
    SettingsController settings,
    FinanceController finance,
    AgendaController agenda,
    ReminderController reminders,
  ) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Restaurar backup?'),
        content: const Text(
            'Os dados atuais serão substituídos pelos dados do arquivo escolhido.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar')),
        ],
      ),
    );
    if (ok != true) return;
    final String? raw = await backup.pickBackupRaw();
    if (!context.mounted) return;
    if (raw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum arquivo selecionado')),
      );
      return;
    }
    RestoreOutcome outcome = await backup.restoreFromRaw(raw);
    if (outcome == RestoreOutcome.needsPin) {
      if (!context.mounted) return;
      final String? pin = await _pinDialog(
        context,
        'PIN do backup',
        'Este backup está protegido. Informe o mesmo PIN usado no app.',
      );
      if (pin == null || pin.isEmpty) return;
      outcome = await backup.restoreFromRaw(raw, pin: pin);
    }
    if (!context.mounted) return;
    if (outcome == RestoreOutcome.ok) {
      settings.reload();
      finance.reload();
      agenda.reload();
      reminders.reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup restaurado com sucesso!')),
      );
    } else if (outcome == RestoreOutcome.wrongPinOrCorrupted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN incorreto ou arquivo corrompido')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível restaurar o arquivo')),
      );
    }
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection();

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle('Privacidade', icon: Icons.lock_outline),
        Card(
          child: Column(
            children: <Widget>[
              SwitchListTile(
                secondary: const Icon(Icons.password),
                title: const Text('Bloquear com PIN'),
                subtitle: const Text('Protege o app ao abrir'),
                value: settings.settings.pinEnabled,
                onChanged: (bool v) async {
                  if (!v) {
                    settings.setPin(enabled: false, pin: '');
                    return;
                  }
                  final String? pin = await _setPinDialog(context);
                  if (pin != null) settings.setPin(enabled: true, pin: pin);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle('Sobre', icon: Icons.info_outline),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('${AppInfo.appName} • v${AppInfo.version}',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  'Gestor financeiro pessoal, 100% offline. Seus dados ficam apenas no seu aparelho, com backup opcional por e-mail, WhatsApp ou Google Drive.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Future<String?> _textDialog(
  BuildContext context,
  String title,
  TextEditingController controller, {
  TextInputType keyboard = TextInputType.text,
  int? maxLength,
}) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: keyboard,
        maxLength: maxLength,
        decoration: const InputDecoration(labelText: 'Valor'),
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}

Future<String?> _setPinDialog(BuildContext context) {
  final TextEditingController pin = TextEditingController();
  final TextEditingController confirm = TextEditingController();
  String? error;
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) => AlertDialog(
        title: const Text('Defina um PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: pin,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: SecurityRules.pinLength,
              decoration: const InputDecoration(labelText: 'PIN (4 dígitos)'),
            ),
            TextField(
              controller: confirm,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: SecurityRules.pinLength,
              decoration: const InputDecoration(labelText: 'Confirme o PIN'),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final String a = pin.text.trim();
              final String b = confirm.text.trim();
              if (!RegExp(r'^\d{4}$').hasMatch(a)) {
                setState(() => error = 'Use exatamente 4 dígitos');
                return;
              }
              if (a != b) {
                setState(() => error = 'Os PINs não coincidem');
                return;
              }
              Navigator.pop(context, a);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    ),
  );
}

Future<String?> _pinDialog(
  BuildContext context,
  String title,
  String message,
) {
  final TextEditingController controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(message),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: SecurityRules.pinLength,
            decoration: const InputDecoration(labelText: 'PIN'),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Restaurar'),
        ),
      ],
    ),
  );
}

Future<void> _pickColor(
  BuildContext context,
  Color initial,
  ValueChanged<String> onPicked,
) async {
  Color current = initial;
  final Color? result = await showDialog<Color>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('Escolha uma cor'),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: current,
          onColorChanged: (Color c) => current = c,
          enableAlpha: false,
          labelTypes: const <ColorLabelType>[],
          pickerAreaHeightPercent: 0.7,
        ),
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(context, current),
          child: const Text('Escolher'),
        ),
      ],
    ),
  );
  if (result != null) {
    onPicked(colorToHex(result));
  }
}

Widget _sliderTile(
  BuildContext context,
  String label,
  double value,
  double min,
  double max,
  ValueChanged<double> onChanged,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(label),
            Text('${(value * 100).toStringAsFixed(0)}%'),
          ],
        ),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}
