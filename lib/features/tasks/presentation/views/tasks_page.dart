import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/task_item.dart';
import '../viewmodels/tasks_view_model.dart';
import 'task_form_page.dart';

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  late DateTime _date;
  TaskStatus? _filter;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final asyncTasks = ref.watch(tasksViewModelProvider(_date));
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tarefas'),
          actions: [
            IconButton(
              tooltip: 'Adicionar tarefa',
              onPressed: _openForm,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            _DateNavigation(
              date: _date,
              onPrevious: () => _changeDate(-1),
              onNext: () => _changeDate(1),
              onPick: _pickDate,
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: 'Todas',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  _FilterChip(
                    label: 'Pendentes',
                    selected: _filter == TaskStatus.pending,
                    onTap: () => setState(() => _filter = TaskStatus.pending),
                  ),
                  _FilterChip(
                    label: 'Em andamento',
                    selected: _filter == TaskStatus.inProgress,
                    onTap: () =>
                        setState(() => _filter = TaskStatus.inProgress),
                  ),
                  _FilterChip(
                    label: 'Concluídas',
                    selected: _filter == TaskStatus.completed,
                    onTap: () => setState(() => _filter = TaskStatus.completed),
                  ),
                ],
              ),
            ),
            Expanded(
              child: asyncTasks.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: FilledButton.icon(
                    onPressed: () =>
                        ref.invalidate(tasksViewModelProvider(_date)),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tentar novamente'),
                  ),
                ),
                data: (tasks) {
                  final filtered = _filter == null
                      ? tasks
                      : tasks.where((task) => task.status == _filter).toList();
                  if (filtered.isEmpty) return _EmptyTasks(onAdd: _openForm);
                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(tasksViewModelProvider(_date)),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) => _TaskCard(
                        task: filtered[index],
                        onToggle: () => _toggle(filtered[index]),
                        onAction: (action) => _action(filtered[index], action),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openForm,
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  void _changeDate(int days) {
    setState(() => _date = _date.add(Duration(days: days)));
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _openForm([TaskItem? task]) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => TaskFormPage(task: task)));
    ref.invalidate(tasksViewModelProvider(_date));
  }

  Future<void> _toggle(TaskItem task) async {
    final next = task.status == TaskStatus.completed
        ? TaskStatus.pending
        : TaskStatus.completed;
    final saved = await ref
        .read(tasksViewModelProvider(_date).notifier)
        .setStatus(task, next);
    if (!saved && mounted) _showError();
  }

  Future<void> _action(TaskItem task, String action) async {
    final viewModel = ref.read(tasksViewModelProvider(_date).notifier);
    if (action == 'edit') return _openForm(task);
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Excluir tarefa?'),
          content: const Text('O histórico já registrado será preservado.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        ),
      );
      if (confirmed == true && !await viewModel.delete(task) && mounted) {
        _showError();
      }
      return;
    }
    if (action == 'reschedule') {
      final date = await showDatePicker(
        context: context,
        initialDate: _date.add(const Duration(days: 1)),
        firstDate: _date,
        lastDate: _date.add(const Duration(days: 3650)),
      );
      if (date != null && !await viewModel.reschedule(task, date) && mounted) {
        _showError();
      }
      return;
    }
    final status = action == 'start'
        ? TaskStatus.inProgress
        : TaskStatus.postponed;
    if (!await viewModel.setStatus(task, status) && mounted) _showError();
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível salvar a alteração.')),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onAction,
  });

  final TaskItem task;
  final VoidCallback onToggle;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final completed = task.status == TaskStatus.completed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 4, 10),
        child: Row(
          children: [
            Checkbox(value: completed, onChanged: (_) => onToggle()),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: completed ? TextDecoration.lineThrough : null,
                      color: task.isOverdue ? AppColors.warning : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      _duration(task.estimatedMinutes),
                      if (task.category != null) task.category!.name,
                      _statusLabel(task.status),
                    ].join(' • '),
                  ),
                  if (task.isOverdue)
                    const Text(
                      'Prazo vencido',
                      style: TextStyle(color: AppColors.warning, fontSize: 12),
                    ),
                ],
              ),
            ),
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: _priorityColor(task.priority),
                shape: BoxShape.circle,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: onAction,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'start', child: Text('Iniciar')),
                PopupMenuItem(value: 'postpone', child: Text('Adiar')),
                PopupMenuItem(value: 'reschedule', child: Text('Reagendar')),
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Excluir')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateNavigation extends StatelessWidget {
  const _DateNavigation({
    required this.date,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: TextButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(_date(date)),
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.task_alt_rounded, size: 54),
          const SizedBox(height: 12),
          const Text('Nenhuma tarefa para esta seleção.'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Adicionar tarefa'),
          ),
        ],
      ),
    );
  }
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _duration(int minutes) => minutes < 60
    ? '$minutes min'
    : '${minutes ~/ 60}h${minutes % 60 == 0 ? '' : ' ${minutes % 60}min'}';

String _statusLabel(TaskStatus status) => switch (status) {
  TaskStatus.inProgress => 'Em andamento',
  TaskStatus.completed => 'Concluída',
  TaskStatus.postponed => 'Adiada',
  TaskStatus.cancelled => 'Cancelada',
  _ => 'Pendente',
};

Color _priorityColor(TaskPriority priority) => switch (priority) {
  TaskPriority.low => AppColors.success,
  TaskPriority.medium => AppColors.warning,
  TaskPriority.high => Colors.redAccent,
};
