import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/personal_reservation.dart';
import '../viewmodels/personal_reservations_view_model.dart';

class PersonalReservationsPage extends ConsumerWidget {
  const PersonalReservationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservations = ref.watch(personalReservationsViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reservas pessoais')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: reservations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: FilledButton(
            onPressed: () =>
                ref.invalidate(personalReservationsViewModelProvider),
            child: const Text('Tentar novamente'),
          ),
        ),
        data: (items) => items.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Cadastre refeições, descanso ou outros horários que não devem receber tarefas.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: items.length,
                itemBuilder: (_, index) => _ReservationTile(
                  reservation: items[index],
                  onDelete: () => _delete(context, ref, items[index]),
                ),
              ),
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_ReservationDraft>(
      context: context,
      builder: (_) => const _ReservationDialog(),
    );
    if (result == null) return;
    final saved = await ref
        .read(personalReservationsViewModelProvider.notifier)
        .create(
          title: result.title,
          weekdays: result.weekdays,
          startMinutes: result.startMinutes,
          endMinutes: result.endMinutes,
        );
    if (!saved && context.mounted) _error(context);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    PersonalReservation reservation,
  ) async {
    final saved = await ref
        .read(personalReservationsViewModelProvider.notifier)
        .delete(reservation.id);
    if (!saved && context.mounted) _error(context);
  }

  void _error(BuildContext context) => ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Não foi possível salvar.')));
}

class _ReservationTile extends StatelessWidget {
  const _ReservationTile({required this.reservation, required this.onDelete});
  final PersonalReservation reservation;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.event_busy_outlined),
      title: Text(reservation.title),
      subtitle: Text(
        '${_time(reservation.startMinutes)}–${_time(reservation.endMinutes)} • ${_weekdays(reservation.weekdays)}',
      ),
      trailing: IconButton(
        tooltip: 'Excluir',
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline_rounded),
      ),
    ),
  );
}

class _ReservationDialog extends StatefulWidget {
  const _ReservationDialog();
  @override
  State<_ReservationDialog> createState() => _ReservationDialogState();
}

class _ReservationDialogState extends State<_ReservationDialog> {
  final _title = TextEditingController();
  final _weekdays = <int>{1, 2, 3, 4, 5};
  int _start = 12 * 60;
  int _end = 13 * 60;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nova reserva'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 5,
            children: [
              for (var day = 1; day <= 7; day++)
                FilterChip(
                  label: Text(
                    const ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'][day - 1],
                  ),
                  selected: _weekdays.contains(day),
                  onSelected: (selected) => setState(
                    () => selected ? _weekdays.add(day) : _weekdays.remove(day),
                  ),
                ),
            ],
          ),
          ListTile(
            title: const Text('Início'),
            trailing: Text(_time(_start)),
            onTap: () => _pick(true),
          ),
          ListTile(
            title: const Text('Fim'),
            trailing: Text(_time(_end)),
            onTap: () => _pick(false),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Salvar')),
    ],
  );

  Future<void> _pick(bool start) async {
    final value = start ? _start : _end;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: value ~/ 60, minute: value % 60),
    );
    if (selected != null) {
      setState(() {
        final minutes = selected.hour * 60 + selected.minute;
        start ? _start = minutes : _end = minutes;
      });
    }
  }

  void _submit() {
    if (_title.text.trim().isEmpty || _weekdays.isEmpty || _start == _end) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha nome, dias e horários válidos.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      _ReservationDraft(
        title: _title.text.trim(),
        weekdays: _weekdays,
        startMinutes: _start,
        endMinutes: _end,
      ),
    );
  }
}

class _ReservationDraft {
  const _ReservationDraft({
    required this.title,
    required this.weekdays,
    required this.startMinutes,
    required this.endMinutes,
  });
  final String title;
  final Set<int> weekdays;
  final int startMinutes;
  final int endMinutes;
}

String _time(int value) =>
    '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';
String _weekdays(Set<int> values) => values.length == 7
    ? 'Todos os dias'
    : [
        for (final day in values.toList()..sort())
          const ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'][day - 1],
      ].join(', ');
