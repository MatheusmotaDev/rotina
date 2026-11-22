import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/daily_availability.dart';
import '../../../tasks/domain/models/task_item.dart';
import '../../../tasks/presentation/viewmodels/tasks_view_model.dart';
import '../viewmodels/availability_provider.dart';

class AvailabilityPage extends ConsumerWidget {
  const AvailabilityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(availabilityProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tasks = ref.watch(tasksViewModelProvider(today)).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Disponibilidade de hoje')),
      body: availability.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(availabilityProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ),
        data: (value) => _AvailabilityContent(value: value, tasks: tasks),
      ),
    );
  }
}

class _AvailabilityContent extends StatelessWidget {
  const _AvailabilityContent({required this.value, required this.tasks});

  final DailyAvailability value;
  final List<TaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    final tasksThatDoNotFit = tasks
        .where(
          (task) =>
              task.status != TaskStatus.completed &&
              task.status != TaskStatus.cancelled &&
              !value.canFit(task.estimatedMinutes),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        if (value.provisional)
          const _Notice(
            icon: Icons.info_outline_rounded,
            text: 'Estimativa provisória: o check-in da manhã ainda não foi concluído.',
            color: AppColors.primary,
          ),
        if (value.overloaded)
          const _Notice(
            icon: Icons.error_outline_rounded,
            text: 'O dia está sobrecarregado: compromissos e reservas excedem o período acordado.',
            color: AppColors.warning,
          ),
        if (value.hasConflicts)
          const _Notice(
            icon: Icons.warning_amber_rounded,
            text: 'Existem compromissos com horários sobrepostos.',
            color: AppColors.warning,
          ),
        if (tasksThatDoNotFit.isNotEmpty)
          _Notice(
            icon: Icons.assignment_late_outlined,
            text:
                '${tasksThatDoNotFit.length} tarefa(s) não cabem em nenhuma janela livre contínua.',
            color: AppColors.warning,
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _MetricRow(
                  label: 'Período acordado',
                  value: _duration(value.awakeMinutes),
                ),
                const Divider(),
                _MetricRow(
                  label: 'Compromissos',
                  value: _duration(value.busyMinutes),
                ),
                const Divider(),
                _MetricRow(
                  label: 'Reservas pessoais',
                  value: _duration(value.personalReserveMinutes),
                ),
                const Divider(),
                _MetricRow(
                  label: 'Disponível',
                  value: _duration(value.availableMinutes),
                  highlighted: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text('Janelas livres', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        if (value.freeWindows.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('Nenhuma janela livre neste período.'),
            ),
          )
        else
          ...value.freeWindows.map(
            (window) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.schedule_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text('${_time(window.start)} – ${_time(window.end)}'),
                  subtitle: Text(_duration(window.durationMinutes)),
                ),
              ),
            ),
          ),
        if (tasksThatDoNotFit.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Tarefas que exigem atenção',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...tasksThatDoNotFit.map(
            (task) => Card(
              child: ListTile(
                leading: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                ),
                title: Text(task.title),
                subtitle: Text(
                  'Precisa de ${_duration(task.estimatedMinutes)} contínuos.',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              color: highlighted ? AppColors.primary : null,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

String _duration(int minutes) {
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  if (hours == 0) return '$remainder min';
  if (remainder == 0) return '${hours}h';
  return '${hours}h ${remainder}min';
}

String _time(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
