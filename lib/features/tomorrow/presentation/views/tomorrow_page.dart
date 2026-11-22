import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/tomorrow_preparation.dart';
import '../viewmodels/tomorrow_view_model.dart';

class TomorrowPage extends ConsumerWidget {
  const TomorrowPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preparation = ref.watch(tomorrowViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Planejar amanhã')),
      body: preparation.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(tomorrowViewModelProvider),
            child: const Text('Tentar novamente'),
          ),
        ),
        data: (value) => _PreparationBody(value: value),
      ),
    );
  }
}

class _PreparationBody extends ConsumerWidget {
  const _PreparationBody({required this.value});

  final TomorrowPreparation value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(
          'Prepare ${_date(value.date)}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.alarm_rounded),
            title: const Text('Despertar pretendido'),
            subtitle: Text(_timeFromMinutes(value.wakeMinutes)),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _pickWake(context, ref),
          ),
        ),
        const SizedBox(height: 16),
        Text('Compromissos', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (value.commitments.isEmpty)
          const Text('Nenhum compromisso recorrente previsto.')
        else
          ...value.commitments.map(
            (item) => Card(
              child: SwitchListTile(
                title: Text(item.title),
                subtitle: Text('${_time(item.start)}–${_time(item.end)}'),
                value: item.confirmed,
                onChanged: (confirmed) => ref
                    .read(tomorrowViewModelProvider.notifier)
                    .toggleCommitment(item.id, confirmed),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          'Pendências de hoje',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (value.pendingTasks.isEmpty)
          const Text('Nenhuma pendência disponível para transferir.')
        else
          ...value.pendingTasks.map(
            (task) => CheckboxListTile(
              title: Text(task.title),
              subtitle: Text('${task.estimatedMinutes} min'),
              value: value.selectedTaskIds.contains(task.id),
              onChanged: (selected) => ref
                  .read(tomorrowViewModelProvider.notifier)
                  .toggleTask(task.id, selected == true),
            ),
          ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Previsão provisória',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('${_duration(value.preview.availableMinutes)} livres'),
                Text(
                  '${value.preview.freePercentage.round()}% do período acordado',
                ),
                Text('${value.preview.freeWindows.length} janelas disponíveis'),
                const SizedBox(height: 8),
                const Text('Esta previsão será revista no check-in de amanhã.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: () => _save(context, ref),
          icon: Icon(value.saved ? Icons.check_rounded : Icons.save_outlined),
          label: Text(
            value.saved ? 'Planejamento confirmado' : 'Confirmar amanhã',
          ),
        ),
      ],
    );
  }

  Future<void> _pickWake(BuildContext context, WidgetRef ref) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: value.wakeMinutes ~/ 60,
        minute: value.wakeMinutes % 60,
      ),
    );
    if (selected != null) {
      await ref
          .read(tomorrowViewModelProvider.notifier)
          .setWakeMinutes(selected.hour * 60 + selected.minute);
    }
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final saved = await ref.read(tomorrowViewModelProvider.notifier).save();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Amanhã foi preparado.'
              : 'Não foi possível salvar o planejamento.',
        ),
      ),
    );
  }
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
String _timeFromMinutes(int value) =>
    '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';
String _duration(int minutes) =>
    minutes < 60 ? '$minutes min' : '${minutes ~/ 60}h ${minutes % 60}min';
