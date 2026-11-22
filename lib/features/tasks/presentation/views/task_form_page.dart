import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/task_item.dart';
import '../viewmodels/tasks_view_model.dart';

class TaskFormPage extends ConsumerStatefulWidget {
  const TaskFormPage({this.task, super.key});

  final TaskItem? task;

  @override
  ConsumerState<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends ConsumerState<TaskFormPage> {
  static const _durations = [15, 30, 45, 60, 90, 120, 180, 240];
  static const _dayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String? _categoryId;
  late TaskPriority _priority;
  late int _duration;
  late DateTime _initialDate;
  DateTime? _deadline;
  late TaskRepeat _repeat;
  late Set<int> _weekdays;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title);
    _descriptionController = TextEditingController(text: task?.description);
    _categoryId = task?.category?.id;
    _priority = task?.priority ?? TaskPriority.medium;
    _duration = task?.estimatedMinutes ?? 30;
    _initialDate = task?.initialDate ?? _today();
    _deadline = task?.deadline;
    _repeat = task?.repeat ?? TaskRepeat.none;
    _weekdays = {...?task?.weekdays};
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(taskCategoriesProvider);
    final editing = widget.task != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Editar tarefa' : 'Nova tarefa')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe um título.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição opcional',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: categories.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => const Text('Categorias indisponíveis'),
                      data: (items) => DropdownButtonFormField<String?>(
                        initialValue: _categoryId,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Sem categoria'),
                          ),
                          ...items.map(
                            (category) => DropdownMenuItem(
                              value: category.id,
                              child: Text(category.name),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _categoryId = value),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Nova categoria',
                    onPressed: _createCategory,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Prioridade',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              SegmentedButton<TaskPriority>(
                segments: const [
                  ButtonSegment(value: TaskPriority.low, label: Text('Baixa')),
                  ButtonSegment(
                    value: TaskPriority.medium,
                    label: Text('Média'),
                  ),
                  ButtonSegment(value: TaskPriority.high, label: Text('Alta')),
                ],
                selected: {_priority},
                onSelectionChanged: (value) =>
                    setState(() => _priority = value.first),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                initialValue: _durations.contains(_duration) ? _duration : 30,
                decoration: const InputDecoration(
                  labelText: 'Duração estimada',
                ),
                items: _durations
                    .map(
                      (minutes) => DropdownMenuItem(
                        value: minutes,
                        child: Text(_durationLabel(minutes)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _duration = value!),
              ),
              const SizedBox(height: 14),
              _DateTile(
                label: 'Data inicial',
                value: _initialDate,
                onTap: () => _pickDate(false),
              ),
              const SizedBox(height: 10),
              _DateTile(
                label: 'Prazo opcional',
                value: _deadline,
                onTap: () => _pickDate(true),
                onClear: _deadline == null
                    ? null
                    : () => setState(() => _deadline = null),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<TaskRepeat>(
                initialValue: _repeat,
                decoration: const InputDecoration(labelText: 'Repetição'),
                items: const [
                  DropdownMenuItem(
                    value: TaskRepeat.none,
                    child: Text('Não repetir'),
                  ),
                  DropdownMenuItem(
                    value: TaskRepeat.daily,
                    child: Text('Todos os dias'),
                  ),
                  DropdownMenuItem(
                    value: TaskRepeat.weekly,
                    child: Text('Semanal'),
                  ),
                ],
                onChanged: (value) => setState(() => _repeat = value!),
              ),
              if (_repeat == TaskRepeat.weekly) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: List.generate(7, (index) {
                    final day = index + 1;
                    return FilterChip(
                      label: Text(_dayLabels[index]),
                      selected: _weekdays.contains(day),
                      onSelected: (selected) => setState(
                        () => selected
                            ? _weekdays.add(day)
                            : _weekdays.remove(day),
                      ),
                    );
                  }),
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
                    : Text(editing ? 'Salvar alterações' : 'Adicionar tarefa'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova categoria'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    try {
      final category = await ref
          .read(tasksRepositoryProvider)
          .createCategory(name);
      ref.invalidate(taskCategoriesProvider);
      setState(() => _categoryId = category.id);
    } catch (_) {
      if (mounted) _showError('Não foi possível criar a categoria.');
    }
  }

  Future<void> _pickDate(bool deadline) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: deadline ? (_deadline ?? _initialDate) : _initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selected == null) return;
    setState(() {
      if (deadline) {
        _deadline = DateTime(
          selected.year,
          selected.month,
          selected.day,
          23,
          59,
        );
      } else {
        _initialDate = selected;
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_repeat == TaskRepeat.weekly && _weekdays.isEmpty) {
      _showError('Selecione pelo menos um dia da semana.');
      return;
    }
    setState(() => _saving = true);
    final repository = ref.read(tasksRepositoryProvider);
    try {
      if (widget.task == null) {
        await repository.create(
          title: _titleController.text,
          description: _descriptionController.text,
          categoryId: _categoryId,
          priority: _priority,
          estimatedMinutes: _duration,
          initialDate: _initialDate,
          deadline: _deadline,
          repeat: _repeat,
          weekdays: _weekdays,
        );
      } else {
        await repository.edit(
          widget.task!,
          title: _titleController.text,
          description: _descriptionController.text,
          categoryId: _categoryId,
          priority: _priority,
          estimatedMinutes: _duration,
          initialDate: _initialDate,
          deadline: _deadline,
          repeat: _repeat,
          weekdays: _weekdays,
        );
      }
      ref.invalidate(tasksViewModelProvider);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _showError('Não foi possível salvar a tarefa.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Theme.of(context).colorScheme.surface,
      leading: const Icon(Icons.calendar_today_outlined),
      title: Text(label),
      subtitle: Text(value == null ? 'Não informado' : _dateLabel(value!)),
      trailing: onClear == null
          ? const Icon(Icons.chevron_right_rounded)
          : IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
            ),
      onTap: onTap,
    );
  }
}

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String _durationLabel(int minutes) {
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  if (hours == 0) return '$remainder min';
  if (remainder == 0) return '${hours}h';
  return '${hours}h ${remainder}min';
}
