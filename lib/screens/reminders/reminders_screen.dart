import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/id_generator.dart';
import '../../data/models/reminder.dart';
import '../../services/media_service.dart';
import '../../services/notification_service.dart';
import '../../services/sound_service.dart';
import '../../state/reminder_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';

String _repeatLabel(ReminderRepeat r) {
  switch (r) {
    case ReminderRepeat.none:
      return 'Uma vez';
    case ReminderRepeat.daily:
      return 'Todo dia';
    case ReminderRepeat.weekly:
      return 'Toda semana';
    case ReminderRepeat.monthly:
      return 'Todo mês';
  }
}

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ReminderController controller = context.watch<ReminderController>();
    final ThemeData theme = Theme.of(context);

    return AppScaffold(
      title: 'Lembretes e alarmes',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
      ),
      body: controller.reminders.isEmpty
          ? EmptyState(
              icon: Icons.alarm_outlined,
              title: 'Nenhum lembrete',
              message:
                  'Crie alarmes para pagar contas, registrar gastos ou escrever no diário.',
              action: FilledButton.icon(
                onPressed: () => _openEditor(context, null),
                icon: const Icon(Icons.add),
                label: const Text('Criar lembrete'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: controller.upcoming.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int index) {
                final Reminder r = controller.upcoming[index];
                return SectionCard(
                  onTap: () => _openEditor(context, r),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.alarm,
                            color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              r.title.isEmpty ? 'Lembrete' : r.title,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (r.message.isNotEmpty)
                              Text(r.message,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall),
                            Text(
                              '${DateHelpers.dateTime.format(r.dateTime)} • ${_repeatLabel(r.repeat)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: r.enabled,
                        onChanged: (bool v) => controller.toggle(r, v),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _openEditor(BuildContext context, Reminder? reminder) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ReminderEditor(reminder: reminder),
    );
  }
}

class _ReminderEditor extends StatefulWidget {
  const _ReminderEditor({this.reminder});

  final Reminder? reminder;

  @override
  State<_ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends State<_ReminderEditor> {
  late TextEditingController _title;
  late TextEditingController _message;
  late DateTime _dateTime;
  late ReminderRepeat _repeat;
  String? _soundPath;

  @override
  void initState() {
    super.initState();
    final Reminder? r = widget.reminder;
    _title = TextEditingController(text: r?.title ?? '');
    _message = TextEditingController(text: r?.message ?? '');
    _dateTime = r?.dateTime ?? DateTime.now().add(const Duration(hours: 1));
    _repeat = r?.repeat ?? ReminderRepeat.none;
    _soundPath = r?.soundPath;
  }

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    if (!mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time == null) return;
    setState(() {
      _dateTime = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickSound() async {
    final MediaService media = context.read<MediaService>();
    final String? path = await media.pickSound();
    if (path != null) setState(() => _soundPath = path);
  }

  Future<void> _save() async {
    final ReminderController controller = context.read<ReminderController>();
    final NotificationService notifications =
        context.read<NotificationService>();
    final SettingsController settings = context.read<SettingsController>();

    final String title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dê um título ao lembrete')),
      );
      return;
    }

    final Reminder reminder = Reminder(
      id: widget.reminder?.id ?? newId(),
      title: title,
      message: _message.text.trim(),
      dateTime: _dateTime,
      repeat: _repeat,
      soundPath: _soundPath,
      enabled: widget.reminder?.enabled ?? true,
    );

    if (widget.reminder == null) {
      controller.add(reminder);
    } else {
      controller.update(reminder);
    }

    if (settings.settings.notificationsEnabled) {
      await notifications.requestPermissions();
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _testSound() async {
    final SoundService sound = context.read<SoundService>();
    final SettingsController settings = context.read<SettingsController>();
    if (_soundPath != null) {
      await sound.playFile(_soundPath!);
    } else {
      await sound.playTap(
        path: settings.settings.notificationSoundPath,
        enabled: true,
        haptics: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.reminder == null ? 'Novo lembrete' : 'Editar lembrete',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _message,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Mensagem'),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              ),
              leading: const Icon(Icons.schedule),
              title: const Text('Data e hora'),
              subtitle: Text(DateHelpers.dateTime.format(_dateTime)),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<ReminderRepeat>(
              initialValue: _repeat,
              decoration: const InputDecoration(
                labelText: 'Repetição',
                prefixIcon: Icon(Icons.repeat),
              ),
              items: ReminderRepeat.values
                  .map(
                    (ReminderRepeat r) => DropdownMenuItem<ReminderRepeat>(
                      value: r,
                      child: Text(_repeatLabel(r)),
                    ),
                  )
                  .toList(),
              onChanged: (ReminderRepeat? v) =>
                  setState(() => _repeat = v ?? ReminderRepeat.none),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickSound,
                    icon: const Icon(Icons.music_note_outlined),
                    label: Text(_soundPath == null
                        ? 'Escolher som'
                        : 'Som: ${_soundPath!.split(RegExp(r'[\\/]')).last}',
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _testSound,
                  icon: const Icon(Icons.play_arrow),
                  tooltip: 'Testar som',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                if (widget.reminder != null)
                  IconButton.filledTonal(
                    onPressed: () {
                      context
                          .read<ReminderController>()
                          .delete(widget.reminder!.id);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Salvar lembrete'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
