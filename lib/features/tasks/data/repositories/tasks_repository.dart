import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/task_item.dart';
import '../../domain/services/task_schedule.dart';

class TasksRepository {
  TasksRepository(this._client);

  final SupabaseClient _client;

  Future<List<TaskCategory>> loadCategories() async {
    final user = _requireUser();
    final rows = await _client
        .from('categorias_tarefas')
        .select()
        .eq('usuario_id', user.id)
        .order('nome');
    return rows
        .map(
          (row) => TaskCategory(
            id: row['id'] as String,
            name: row['nome'] as String,
            color: row['cor'] as String?,
          ),
        )
        .toList();
  }

  Future<TaskCategory> createCategory(String name) async {
    final user = _requireUser();
    final row = await _client
        .from('categorias_tarefas')
        .insert({'usuario_id': user.id, 'nome': name.trim()})
        .select()
        .single();
    return TaskCategory(id: row['id'] as String, name: row['nome'] as String);
  }

  Future<List<TaskItem>> loadForDate(DateTime date) async {
    final user = _requireUser();
    final localDate = _dateOnly(date);
    final dateValue = _dateForDatabase(localDate);
    final taskRows = await _client
        .from('tarefas')
        .select()
        .eq('usuario_id', user.id)
        .eq('ativo', true);
    final occurrenceRows = await _client
        .from('ocorrencias_tarefas')
        .select()
        .eq('usuario_id', user.id)
        .eq('data_local', dateValue);
    final categories = {
      for (final category in await loadCategories()) category.id: category,
    };
    final existingByTask = {
      for (final row in occurrenceRows) row['tarefa_id'] as String: row,
    };

    final applicableRows = taskRows.where((row) {
      final taskId = row['id'] as String;
      return existingByTask.containsKey(taskId) ||
          const TaskSchedule().applies(
            repeat: _repeatFromDatabase(row['repeticao'] as String),
            initialDate: DateTime.parse(row['data_inicial'] as String),
            finalDate: row['data_final'] == null
                ? null
                : DateTime.parse(row['data_final'] as String),
            weekdays: (row['dias_semana'] as List).cast<int>().toSet(),
            date: localDate,
          );
    }).toList();
    final missing = applicableRows
        .where((row) => !existingByTask.containsKey(row['id'] as String))
        .map(
          (row) => {
            'usuario_id': user.id,
            'tarefa_id': row['id'],
            'data_local': dateValue,
          },
        )
        .toList();
    if (missing.isNotEmpty) {
      final inserted = await _client
          .from('ocorrencias_tarefas')
          .upsert(
            missing,
            onConflict: 'usuario_id,tarefa_id,data_local',
            ignoreDuplicates: true,
          )
          .select();
      for (final row in inserted) {
        existingByTask[row['tarefa_id'] as String] = row;
      }
      if (inserted.length < missing.length) {
        final refreshed = await _client
            .from('ocorrencias_tarefas')
            .select()
            .eq('usuario_id', user.id)
            .eq('data_local', dateValue);
        for (final row in refreshed) {
          existingByTask[row['tarefa_id'] as String] = row;
        }
      }
    }

    return applicableRows.map((row) {
      final occurrence = existingByTask[row['id'] as String]!;
      final categoryId = row['categoria_id'] as String?;
      return _fromRows(
        row,
        occurrence,
        categoryId == null ? null : categories[categoryId],
      );
    }).toList()..sort(_compareTasks);
  }

  Future<void> create({
    required String title,
    required String description,
    required String? categoryId,
    required TaskPriority priority,
    required int estimatedMinutes,
    required DateTime initialDate,
    required DateTime? deadline,
    required TaskRepeat repeat,
    required Set<int> weekdays,
  }) async {
    final user = _requireUser();
    await _client.from('tarefas').insert({
      'usuario_id': user.id,
      'categoria_id': categoryId,
      'titulo': title.trim(),
      'descricao': description.trim().isEmpty ? null : description.trim(),
      'prioridade': _priorityForDatabase(priority),
      'duracao_estimada_min': estimatedMinutes,
      'prazo_em': deadline?.toUtc().toIso8601String(),
      'data_inicial': _dateForDatabase(initialDate),
      'repeticao': _repeatForDatabase(repeat),
      'dias_semana': repeat == TaskRepeat.weekly ? weekdays.toList() : <int>[],
    });
  }

  Future<void> edit(
    TaskItem task, {
    required String title,
    required String description,
    required String? categoryId,
    required TaskPriority priority,
    required int estimatedMinutes,
    required DateTime initialDate,
    required DateTime? deadline,
    required TaskRepeat repeat,
    required Set<int> weekdays,
  }) async {
    final user = _requireUser();
    await _client
        .from('tarefas')
        .update({
          'categoria_id': categoryId,
          'titulo': title.trim(),
          'descricao': description.trim().isEmpty ? null : description.trim(),
          'prioridade': _priorityForDatabase(priority),
          'duracao_estimada_min': estimatedMinutes,
          'prazo_em': deadline?.toUtc().toIso8601String(),
          'data_inicial': _dateForDatabase(initialDate),
          'repeticao': _repeatForDatabase(repeat),
          'dias_semana': repeat == TaskRepeat.weekly
              ? weekdays.toList()
              : <int>[],
        })
        .eq('usuario_id', user.id)
        .eq('id', task.id);
  }

  Future<void> setStatus(TaskItem task, TaskStatus status) async {
    final user = _requireUser();
    await _client
        .from('ocorrencias_tarefas')
        .update({
          'estado': _statusForDatabase(status),
          'concluida_em': status == TaskStatus.completed
              ? DateTime.now().toUtc().toIso8601String()
              : null,
        })
        .eq('usuario_id', user.id)
        .eq('id', task.occurrenceId);
  }

  Future<void> reschedule(TaskItem task, DateTime newDate) async {
    final user = _requireUser();
    await setStatus(task, TaskStatus.postponed);
    await _client.from('ocorrencias_tarefas').upsert({
      'usuario_id': user.id,
      'tarefa_id': task.id,
      'data_local': _dateForDatabase(newDate),
      'estado': 'pendente',
    }, onConflict: 'usuario_id,tarefa_id,data_local');
  }

  Future<void> delete(TaskItem task) async {
    final user = _requireUser();
    final history = await _client
        .from('ocorrencias_tarefas')
        .select('id')
        .eq('usuario_id', user.id)
        .eq('tarefa_id', task.id)
        .limit(1);
    if (history.isNotEmpty) {
      await _client
          .from('tarefas')
          .update({'ativo': false})
          .eq('usuario_id', user.id)
          .eq('id', task.id);
    } else {
      await _client
          .from('tarefas')
          .delete()
          .eq('usuario_id', user.id)
          .eq('id', task.id);
    }
  }

  TaskItem _fromRows(
    Map<String, dynamic> task,
    Map<String, dynamic> occurrence,
    TaskCategory? category,
  ) {
    final deadlineValue = task['prazo_em'] as String?;
    final finalValue = task['data_final'] as String?;
    return TaskItem(
      id: task['id'] as String,
      title: task['titulo'] as String,
      description: task['descricao'] as String?,
      category: category,
      priority: _priorityFromDatabase(task['prioridade'] as String),
      estimatedMinutes: task['duracao_estimada_min'] as int,
      deadline: deadlineValue == null
          ? null
          : DateTime.parse(deadlineValue).toLocal(),
      initialDate: DateTime.parse(task['data_inicial'] as String),
      finalDate: finalValue == null ? null : DateTime.parse(finalValue),
      repeat: _repeatFromDatabase(task['repeticao'] as String),
      weekdays: (task['dias_semana'] as List).cast<int>().toSet(),
      occurrenceId: occurrence['id'] as String,
      occurrenceDate: DateTime.parse(occurrence['data_local'] as String),
      status: _statusFromDatabase(occurrence['estado'] as String),
    );
  }

  int _compareTasks(TaskItem a, TaskItem b) {
    final priority = b.priority.index.compareTo(a.priority.index);
    if (priority != 0) return priority;
    return a.title.compareTo(b.title);
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Sessão não encontrada.');
    return user;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _dateForDatabase(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _priorityForDatabase(TaskPriority value) => switch (value) {
    TaskPriority.low => 'baixa',
    TaskPriority.medium => 'media',
    TaskPriority.high => 'alta',
  };

  TaskPriority _priorityFromDatabase(String value) => switch (value) {
    'baixa' => TaskPriority.low,
    'alta' => TaskPriority.high,
    _ => TaskPriority.medium,
  };

  String _repeatForDatabase(TaskRepeat value) => switch (value) {
    TaskRepeat.none => 'nenhuma',
    TaskRepeat.daily => 'diaria',
    TaskRepeat.weekly => 'semanal',
  };

  TaskRepeat _repeatFromDatabase(String value) => switch (value) {
    'diaria' => TaskRepeat.daily,
    'semanal' => TaskRepeat.weekly,
    _ => TaskRepeat.none,
  };

  String _statusForDatabase(TaskStatus value) => switch (value) {
    TaskStatus.pending => 'pendente',
    TaskStatus.inProgress => 'em_andamento',
    TaskStatus.completed => 'concluida',
    TaskStatus.postponed => 'adiada',
    TaskStatus.cancelled => 'cancelada',
  };

  TaskStatus _statusFromDatabase(String value) => switch (value) {
    'em_andamento' => TaskStatus.inProgress,
    'concluida' => TaskStatus.completed,
    'adiada' => TaskStatus.postponed,
    'cancelada' => TaskStatus.cancelled,
    _ => TaskStatus.pending,
  };
}
