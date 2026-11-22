import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/recurring_commitment.dart';
import '../viewmodels/commitments_view_model.dart';

class CommitmentFormPage extends ConsumerStatefulWidget {
  const CommitmentFormPage({this.commitment, super.key});

  final RecurringCommitment? commitment;

  @override
  ConsumerState<CommitmentFormPage> createState() => _CommitmentFormPageState();
}

class _CommitmentFormPageState extends ConsumerState<CommitmentFormPage> {
  static const _dayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  static const _commuteOptions = [0, 15, 30, 45, 60, 90, 120];
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late CommitmentType _type;
  late bool _mandatory;
  late Set<int> _weekdays;
  late int _startMinutes;
  late int _endMinutes;
  late int _commuteBefore;
  late int _commuteAfter;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final commitment = widget.commitment;
    _titleController = TextEditingController(text: commitment?.title);
    _type = commitment?.type ?? CommitmentType.other;
    _mandatory = commitment?.mandatory ?? true;
    _weekdays = {...?commitment?.weekdays};
    _startMinutes = commitment?.startMinutes ?? 8 * 60;
    _endMinutes = commitment?.endMinutes ?? 9 * 60;
    _commuteBefore = commitment?.commuteBeforeMinutes ?? 0;
    _commuteAfter = commitment?.commuteAfterMinutes ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.commitment != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar compromisso' : 'Novo compromisso'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe um título.'
                    : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<CommitmentType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: CommitmentType.work,
                    child: Text('Trabalho'),
                  ),
                  DropdownMenuItem(
                    value: CommitmentType.college,
                    child: Text('Faculdade'),
                  ),
                  DropdownMenuItem(
                    value: CommitmentType.other,
                    child: Text('Outro'),
                  ),
                ],
                onChanged: (value) => setState(() => _type = value!),
              ),
              const SizedBox(height: 14),
              Card(
                child: SwitchListTile(
                  value: _mandatory,
                  onChanged: (value) => setState(() => _mandatory = value),
                  secondary: Icon(
                    _mandatory
                        ? Icons.lock_outline_rounded
                        : Icons.swap_horiz_rounded,
                  ),
                  title: Text(_mandatory ? 'Obrigatório' : 'Flexível'),
                  subtitle: Text(
                    _mandatory
                        ? 'Este horário deve ser preservado no planejamento.'
                        : 'Este horário pode ser considerado em sugestões de ajuste.',
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Em quais dias?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  return FilterChip(
                    label: Text(_dayLabels[index]),
                    selected: _weekdays.contains(day),
                    onSelected: (selected) => setState(
                      () =>
                          selected ? _weekdays.add(day) : _weekdays.remove(day),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: 'Início',
                      minutes: _startMinutes,
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeField(
                      label: 'Término',
                      minutes: _endMinutes,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Deslocamento',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _CommuteField(
                      label: 'Antes',
                      value: _commuteBefore,
                      options: _commuteOptions,
                      onChanged: (value) =>
                          setState(() => _commuteBefore = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CommuteField(
                      label: 'Depois',
                      value: _commuteAfter,
                      options: _commuteOptions,
                      onChanged: (value) =>
                          setState(() => _commuteAfter = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        editing ? 'Salvar alterações' : 'Adicionar compromisso',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime(bool start) async {
    final current = start ? _startMinutes : _endMinutes;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (selected == null) return;
    setState(() {
      final minutes = selected.hour * 60 + selected.minute;
      start ? _startMinutes = minutes : _endMinutes = minutes;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_weekdays.isEmpty) {
      _showError('Selecione pelo menos um dia da semana.');
      return;
    }
    if (_startMinutes == _endMinutes) {
      _showError('O início e o término não podem ser iguais.');
      return;
    }

    setState(() => _saving = true);
    final viewModel = ref.read(commitmentsViewModelProvider.notifier);
    final commitment = widget.commitment;
    final saved = commitment == null
        ? await viewModel.create(
            title: _titleController.text,
            type: _type,
            mandatory: _mandatory,
            weekdays: _weekdays,
            startMinutes: _startMinutes,
            endMinutes: _endMinutes,
            commuteBeforeMinutes: _commuteBefore,
            commuteAfterMinutes: _commuteAfter,
          )
        : await viewModel.edit(
            commitment,
            title: _titleController.text,
            type: _type,
            mandatory: _mandatory,
            weekdays: _weekdays,
            startMinutes: _startMinutes,
            endMinutes: _endMinutes,
            commuteBeforeMinutes: _commuteBefore,
            commuteAfterMinutes: _commuteAfter,
          );
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) {
      Navigator.pop(context);
    } else {
      _showError('Não foi possível salvar o compromisso.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.minutes,
    required this.onTap,
  });

  final String label;
  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.schedule),
        ),
        child: Text(_formatTime(minutes)),
      ),
    );
  }
}

class _CommuteField extends StatelessWidget {
  const _CommuteField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: options
          .map(
            (minutes) =>
                DropdownMenuItem(value: minutes, child: Text('$minutes min')),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

String _formatTime(int minutes) {
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}
