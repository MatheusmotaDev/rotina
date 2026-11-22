import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tasks/domain/models/task_item.dart';
import '../../../tasks/presentation/viewmodels/tasks_view_model.dart';
import '../../domain/models/focus_session.dart';
import '../viewmodels/focus_view_model.dart';

class FocusPage extends ConsumerStatefulWidget {
  const FocusPage({super.key});

  @override
  ConsumerState<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends ConsumerState<FocusPage> {
  Timer? _ticker;
  FocusMode _mode = FocusMode.pomodoro;
  int _pomodoroMinutes = 25;
  String? _taskOccurrenceId;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(focusViewModelProvider);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Foco')),
        body: session.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: FilledButton(
              onPressed: () => ref.invalidate(focusViewModelProvider),
              child: const Text('Tentar novamente'),
            ),
          ),
          data: (value) =>
              value == null ? _setup(context) : _activeSession(context, value),
        ),
      ),
    );
  }

  Widget _setup(BuildContext context) {
    final tasks = ref.watch(tasksViewModelProvider(_today)).value ?? const [];
    final selectable = tasks
        .where((task) => task.status != TaskStatus.completed)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Como você quer focar?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),
        SegmentedButton<FocusMode>(
          segments: const [
            ButtonSegment(value: FocusMode.pomodoro, label: Text('Pomodoro')),
            ButtonSegment(
              value: FocusMode.free,
              label: Text('Cronômetro livre'),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (value) => setState(() => _mode = value.first),
        ),
        if (_mode == FocusMode.pomodoro) ...[
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            initialValue: _pomodoroMinutes,
            decoration: const InputDecoration(labelText: 'Duração'),
            items: const [15, 25, 40, 50, 60]
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text('$value minutos'),
                  ),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => _pomodoroMinutes = value ?? 25),
          ),
        ],
        const SizedBox(height: 20),
        DropdownButtonFormField<String?>(
          initialValue: _taskOccurrenceId,
          decoration: const InputDecoration(labelText: 'Tarefa (opcional)'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Sem tarefa vinculada'),
            ),
            ...selectable.map(
              (task) => DropdownMenuItem<String?>(
                value: task.occurrenceId,
                child: Text(task.title, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: (value) => setState(() => _taskOccurrenceId = value),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: _start,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Iniciar sessão'),
        ),
      ],
    );
  }

  Widget _activeSession(BuildContext context, FocusSession session) {
    final elapsed = session.elapsed();
    final target = Duration(minutes: session.plannedMinutes ?? 25);
    final remaining = session.mode == FocusMode.pomodoro
        ? target - elapsed
        : elapsed;
    final display = remaining.isNegative ? Duration.zero : remaining;
    final paused = session.state == FocusSessionState.paused;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              paused ? Icons.pause_circle_outline : Icons.timer_outlined,
              size: 72,
            ),
            const SizedBox(height: 18),
            Text(
              _formatDuration(display),
              style: Theme.of(context).textTheme.displayMedium,
              semanticsLabel: '${display.inMinutes} minutos',
            ),
            const SizedBox(height: 8),
            Text(
              paused
                  ? 'Sessão pausada'
                  : session.mode == FocusMode.pomodoro
                  ? 'Pomodoro em andamento'
                  : 'Cronômetro em andamento',
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: paused ? _resume : _pause,
                  icon: Icon(
                    paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  ),
                  label: Text(paused ? 'Retomar' : 'Pausar'),
                ),
                OutlinedButton.icon(
                  onPressed: _finish,
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Encerrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _start() async {
    final saved = await ref
        .read(focusViewModelProvider.notifier)
        .start(
          _mode,
          taskOccurrenceId: _taskOccurrenceId,
          plannedMinutes: _mode == FocusMode.pomodoro ? _pomodoroMinutes : null,
        );
    if (!saved && mounted) _error();
  }

  Future<void> _pause() async {
    if (!await ref.read(focusViewModelProvider.notifier).pause() && mounted) {
      _error();
    }
  }

  Future<void> _resume() async {
    if (!await ref.read(focusViewModelProvider.notifier).resume() && mounted) {
      _error();
    }
  }

  Future<void> _finish() async {
    if (!await ref.read(focusViewModelProvider.notifier).finish() && mounted) {
      _error();
    }
  }

  void _error() => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Não foi possível atualizar a sessão.')),
  );
}

String _formatDuration(Duration value) {
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
