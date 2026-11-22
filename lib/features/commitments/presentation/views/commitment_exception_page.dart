import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/daily_commitment.dart';
import '../../domain/models/recurring_commitment.dart';
import '../viewmodels/commitments_view_model.dart';

class CommitmentExceptionPage extends ConsumerStatefulWidget {
  const CommitmentExceptionPage({required this.commitment, super.key});

  final RecurringCommitment commitment;

  @override
  ConsumerState<CommitmentExceptionPage> createState() =>
      _CommitmentExceptionPageState();
}

class _CommitmentExceptionPageState
    extends ConsumerState<CommitmentExceptionPage> {
  late DateTime _date;
  CommitmentExceptionAction _action = CommitmentExceptionAction.cancelled;
  late int _startMinutes;
  late int _endMinutes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _date = _nextOccurrence(widget.commitment.weekdays);
    _startMinutes = widget.commitment.startMinutes;
    _endMinutes = widget.commitment.endMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustar uma data')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            Text(
              widget.commitment.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'A mudança valerá somente para a data escolhida. A rotina semanal será preservada.',
            ),
            const SizedBox(height: 24),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: Theme.of(context).colorScheme.surface,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Data'),
              subtitle: Text(_formatDate(_date)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: 18),
            RadioGroup<CommitmentExceptionAction>(
              groupValue: _action,
              onChanged: (value) => setState(() => _action = value!),
              child: const Column(
                children: [
                  RadioListTile(
                    value: CommitmentExceptionAction.cancelled,
                    title: Text('Cancelar nesta data'),
                    subtitle: Text('O horário ficará livre somente neste dia.'),
                  ),
                  RadioListTile(
                    value: CommitmentExceptionAction.changed,
                    title: Text('Alterar o horário'),
                    subtitle: Text('Use outro início e término nesta data.'),
                  ),
                  RadioListTile(
                    value: CommitmentExceptionAction.defaultSchedule,
                    title: Text('Restaurar horário padrão'),
                    subtitle: Text('Remove uma alteração feita anteriormente.'),
                  ),
                ],
              ),
            ),
            if (_action == CommitmentExceptionAction.changed) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _TimeTile(
                      label: 'Início',
                      minutes: _startMinutes,
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeTile(
                      label: 'Término',
                      minutes: _endMinutes,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar ajuste'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      selectableDayPredicate: (date) =>
          widget.commitment.weekdays.contains(date.weekday),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _pickTime(bool start) async {
    final current = start ? _startMinutes : _endMinutes;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (selected == null) return;
    setState(() {
      final value = selected.hour * 60 + selected.minute;
      start ? _startMinutes = value : _endMinutes = value;
    });
  }

  Future<void> _save() async {
    if (_action == CommitmentExceptionAction.changed &&
        _startMinutes == _endMinutes) {
      _showError('O início e o término não podem ser iguais.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(commitmentsRepositoryProvider)
          .saveException(
            commitment: widget.commitment,
            date: _date,
            action: _action,
            changedStartMinutes: _startMinutes,
            changedEndMinutes: _endMinutes,
          );
      ref.invalidate(dailyCommitmentsProvider);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _showError('Não foi possível salvar o ajuste desta data.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.minutes,
    required this.onTap,
  });

  final String label;
  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Theme.of(context).colorScheme.surface,
      title: Text(label),
      subtitle: Text(_formatTime(minutes)),
      onTap: onTap,
    );
  }
}

DateTime _nextOccurrence(Set<int> weekdays) {
  var date = DateTime.now();
  date = DateTime(date.year, date.month, date.day);
  for (var offset = 0; offset < 7; offset++) {
    final candidate = date.add(Duration(days: offset));
    if (weekdays.contains(candidate.weekday)) return candidate;
  }
  return date;
}

String _formatDate(DateTime date) {
  const months = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];
  return '${date.day} de ${months[date.month - 1]} de ${date.year}';
}

String _formatTime(int minutes) {
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}
