import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/notification_preferences.dart';
import '../viewmodels/notification_preferences_view_model.dart';

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(notificationPreferencesViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: preferences.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: FilledButton(
            onPressed: () =>
                ref.invalidate(notificationPreferencesViewModelProvider),
            child: const Text('Tentar novamente'),
          ),
        ),
        data: (value) => _SettingsBody(value: value),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.value});
  final NotificationPreferences value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(
      notificationPreferencesViewModelProvider.notifier,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'As notificações são opcionais. O aplicativo continua funcionando se a permissão for negada.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _requestPermission(context, notifier),
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Permitir notificações no dispositivo'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Check-in da manhã'),
          subtitle: Text('Todos os dias às ${_time(value.checkinMinutes)}'),
          value: value.checkin,
          onChanged: (enabled) =>
              notifier.setPreferences(value.copyWith(checkin: enabled)),
        ),
        if (value.checkin)
          ListTile(
            title: const Text('Horário do check-in'),
            trailing: Text(_time(value.checkinMinutes)),
            onTap: () => _pickTime(
              context,
              value.checkinMinutes,
              (minutes) => notifier.setPreferences(
                value.copyWith(checkinMinutes: minutes),
              ),
            ),
          ),
        SwitchListTile(
          title: const Text('Início de tarefas'),
          value: value.taskStarts,
          onChanged: (enabled) =>
              notifier.setPreferences(value.copyWith(taskStarts: enabled)),
        ),
        SwitchListTile(
          title: const Text('Compromissos'),
          value: value.commitments,
          onChanged: (enabled) =>
              notifier.setPreferences(value.copyWith(commitments: enabled)),
        ),
        if (value.taskStarts || value.commitments)
          DropdownButtonFormField<int>(
            initialValue: value.leadMinutes,
            decoration: const InputDecoration(
              labelText: 'Avisar antes do início',
            ),
            items: const [0, 5, 10, 15, 30, 60]
                .map(
                  (minutes) => DropdownMenuItem(
                    value: minutes,
                    child: Text('$minutes min'),
                  ),
                )
                .toList(),
            onChanged: (minutes) {
              if (minutes != null) {
                notifier.setPreferences(value.copyWith(leadMinutes: minutes));
              }
            },
          ),
        SwitchListTile(
          title: const Text('Fim de pausas'),
          value: value.breakEnd,
          onChanged: (enabled) =>
              notifier.setPreferences(value.copyWith(breakEnd: enabled)),
        ),
        SwitchListTile(
          title: const Text('Resumo noturno'),
          subtitle: Text('Todos os dias às ${_time(value.nightlyMinutes)}'),
          value: value.nightlySummary,
          onChanged: (enabled) =>
              notifier.setPreferences(value.copyWith(nightlySummary: enabled)),
        ),
        if (value.nightlySummary)
          ListTile(
            title: const Text('Horário do resumo'),
            trailing: Text(_time(value.nightlyMinutes)),
            onTap: () => _pickTime(
              context,
              value.nightlyMinutes,
              (minutes) => notifier.setPreferences(
                value.copyWith(nightlyMinutes: minutes),
              ),
            ),
          ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => _save(context, notifier),
          icon: const Icon(Icons.save_outlined),
          label: const Text('Salvar preferências'),
        ),
      ],
    );
  }

  Future<void> _requestPermission(
    BuildContext context,
    NotificationPreferencesViewModel notifier,
  ) async {
    final granted = await notifier.requestPermission();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? 'Permissão concedida.'
              : 'Permissão negada. Você pode continuar usando o aplicativo.',
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    NotificationPreferencesViewModel notifier,
  ) async {
    final saved = await notifier.save();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Preferências atualizadas.'
              : 'Não foi possível salvar as preferências.',
        ),
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    int current,
    ValueChanged<int> onSelected,
  ) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (selected != null) onSelected(selected.hour * 60 + selected.minute);
  }
}

String _time(int value) =>
    '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';
