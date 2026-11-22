import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/break_session.dart';
import '../viewmodels/breaks_view_model.dart';

class BreaksPage extends ConsumerStatefulWidget {
  const BreaksPage({super.key});

  @override
  ConsumerState<BreaksPage> createState() => _BreaksPageState();
}

class _BreaksPageState extends ConsumerState<BreaksPage> {
  Timer? _ticker;
  String? _remindedSessionId;

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
    final sessions = ref.watch(breaksViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pausas e descanso')),
      body: sessions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(breaksViewModelProvider),
            child: const Text('Tentar novamente'),
          ),
        ),
        data: (items) {
          final active = items.where((item) => item.active).firstOrNull;
          if (active != null) _scheduleReminder(active);
          final history = items.where((item) => !item.active).toList();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (active == null) _startCard(context) else _activeCard(active),
              const SizedBox(height: 28),
              Text(
                'Histórico recente',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (history.isEmpty)
                const Text('Nenhuma pausa encerrada ainda.')
              else
                ...history.map(_historyTile),
            ],
          );
        },
      ),
    );
  }

  Widget _startCard(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.self_improvement_rounded, size: 48),
          const SizedBox(height: 12),
          Text(
            'Hora de respirar',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _showStartDialog,
            icon: const Icon(Icons.coffee_rounded),
            label: const Text('Iniciar pausa'),
          ),
        ],
      ),
    ),
  );

  Widget _activeCard(BreakSession session) {
    final plannedEnd = session.plannedEnd;
    final remaining = plannedEnd == null
        ? Duration.zero
        : plannedEnd.difference(DateTime.now());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.coffee_rounded, size: 48),
            const SizedBox(height: 12),
            Text(
              remaining.isNegative
                  ? 'Tempo planejado encerrado'
                  : '${remaining.inMinutes}:${remaining.inSeconds.remainder(60).toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text('Em descanso há ${_duration(session.elapsed())}'),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _finish(session),
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Encerrar pausa'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyTile(BreakSession session) => Card(
    child: ListTile(
      leading: const Icon(Icons.history_rounded),
      title: Text('${_duration(session.elapsed())} de descanso'),
      subtitle: Text(
        '${_date(session.startedAt)} • ${_time(session.startedAt)}–${_time(session.endedAt!)}',
      ),
    ),
  );

  Future<void> _showStartDialog() async {
    var minutes = 15;
    var reminder = true;
    final result = await showDialog<(int, bool)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Iniciar pausa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: minutes,
                decoration: const InputDecoration(labelText: 'Duração'),
                items: const [5, 10, 15, 20, 30, 45, 60]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text('$value minutos'),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => minutes = value ?? 15),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Lembrar ao terminar'),
                value: reminder,
                onChanged: (value) => setDialogState(() => reminder = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, (minutes, reminder)),
              child: const Text('Iniciar'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    final saved = await ref
        .read(breaksViewModelProvider.notifier)
        .start(plannedMinutes: result.$1, reminderEnabled: result.$2);
    if (!saved && mounted) _error();
  }

  Future<void> _finish(BreakSession session) async {
    final saved = await ref
        .read(breaksViewModelProvider.notifier)
        .finish(session);
    if (!saved && mounted) _error();
  }

  void _scheduleReminder(BreakSession session) {
    if (!session.reminderDue() || _remindedSessionId == session.id) return;
    _remindedSessionId = session.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pausa concluída'),
          content: const Text('O tempo de descanso planejado terminou.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
    });
  }

  void _error() => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Não foi possível registrar a pausa.')),
  );
}

String _duration(Duration value) =>
    value.inMinutes < 1 ? '${value.inSeconds}s' : '${value.inMinutes} min';
String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
