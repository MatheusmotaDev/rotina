import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/daily_plan.dart';

class StoredPlan {
  const StoredPlan({
    required this.id,
    required this.state,
    required this.version,
    required this.tasks,
    required this.proposal,
  });

  final String? id;
  final PlanState state;
  final int version;
  final List<PlannedTask> tasks;
  final ReplanningProposal? proposal;
}

class PlanningRepository {
  PlanningRepository(this._client);

  final SupabaseClient _client;

  Future<StoredPlan> load(DateTime date) async {
    final user = _requireUser();
    final planning = await _client
        .from('planejamentos_diarios')
        .select()
        .eq('usuario_id', user.id)
        .eq('data_local', _date(date))
        .maybeSingle();
    if (planning == null) {
      return const StoredPlan(
        id: null,
        state: PlanState.provisional,
        version: 1,
        tasks: [],
        proposal: null,
      );
    }
    final planningId = planning['id'] as String;
    final tasks = await _loadBlocks(planningId);
    final proposalRow = await _client
        .from('propostas_replanejamento')
        .select()
        .eq('usuario_id', user.id)
        .eq('planejamento_id', planningId)
        .eq('estado', 'pendente')
        .order('criado_em', ascending: false)
        .limit(1)
        .maybeSingle();
    final proposal = proposalRow == null
        ? null
        : await _loadProposal(proposalRow, tasks);
    return StoredPlan(
      id: planningId,
      state: _planState(planning['estado'] as String),
      version: planning['versao'] as int,
      tasks: tasks,
      proposal: proposal,
    );
  }

  Future<void> confirmInitial(DateTime date, List<PlannedTask> tasks) async {
    final user = _requireUser();
    final planning = await _client
        .from('planejamentos_diarios')
        .upsert({
          'usuario_id': user.id,
          'data_local': _date(date),
          'estado': 'confirmado',
        }, onConflict: 'usuario_id,data_local')
        .select()
        .single();
    if (tasks.isEmpty) return;
    await _client.from('blocos_agenda').insert([
      for (final task in tasks)
        {
          'usuario_id': user.id,
          'planejamento_id': planning['id'],
          'data_local': _date(date),
          'ocorrencia_tarefa_id': task.occurrenceId,
          'tipo': 'tarefa',
          'titulo': task.title,
          'inicio_em': task.start.toUtc().toIso8601String(),
          'fim_em': task.end.toUtc().toIso8601String(),
        },
    ]);
  }

  Future<void> createProposal({
    required String planningId,
    required int baseVersion,
    required DateTime date,
    required String reason,
    required List<PlannedTask> current,
    required List<PlannedTask> suggested,
  }) async {
    final user = _requireUser();
    final proposal = await _client
        .from('propostas_replanejamento')
        .insert({
          'usuario_id': user.id,
          'planejamento_id': planningId,
          'versao_base': baseVersion,
          'motivo': reason,
        })
        .select()
        .single();
    final currentByOccurrence = {
      for (final task in current) task.occurrenceId: task,
    };
    final suggestedByOccurrence = {
      for (final task in suggested) task.occurrenceId: task,
    };
    final changes = <Map<String, dynamic>>[];
    for (final task in current) {
      final replacement = suggestedByOccurrence[task.occurrenceId];
      if (replacement == null) {
        changes.add(
          _changeBase(user.id, proposal['id'] as String, planningId, date)
            ..addAll({'bloco_id': task.blockId, 'acao': 'remover'}),
        );
      } else {
        changes.add(
          _changeBase(user.id, proposal['id'] as String, planningId, date)
            ..addAll({
              'bloco_id': task.blockId,
              'acao': 'mover',
              'novo_inicio_em': replacement.start.toUtc().toIso8601String(),
              'novo_fim_em': replacement.end.toUtc().toIso8601String(),
            }),
        );
      }
    }
    for (final task in suggested) {
      if (currentByOccurrence.containsKey(task.occurrenceId)) continue;
      changes.add(
        _changeBase(user.id, proposal['id'] as String, planningId, date)
          ..addAll({
            'ocorrencia_tarefa_id': task.occurrenceId,
            'acao': 'inserir',
            'novo_inicio_em': task.start.toUtc().toIso8601String(),
            'novo_fim_em': task.end.toUtc().toIso8601String(),
          }),
      );
    }
    if (changes.isNotEmpty) {
      await _client.from('alteracoes_proposta').insert(changes);
    }
  }

  Future<void> adjust(PlannedTask task, DateTime start) async {
    final user = _requireUser();
    final end = start.add(Duration(minutes: task.durationMinutes));
    await _client
        .from('alteracoes_proposta')
        .update({
          'novo_inicio_em': start.toUtc().toIso8601String(),
          'novo_fim_em': end.toUtc().toIso8601String(),
        })
        .eq('usuario_id', user.id)
        .eq('id', task.changeId!);
  }

  Future<void> reject(String proposalId) async {
    final user = _requireUser();
    await _client
        .from('propostas_replanejamento')
        .update({
          'estado': 'rejeitada',
          'decidido_em': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('usuario_id', user.id)
        .eq('id', proposalId)
        .eq('estado', 'pendente');
  }

  Future<void> approve(String proposalId) => _client.rpc<void>(
    'aplicar_proposta_replanejamento',
    params: {'p_proposta_id': proposalId},
  );

  Future<List<PlannedTask>> _loadBlocks(String planningId) async {
    final user = _requireUser();
    final rows = await _client
        .from('blocos_agenda')
        .select()
        .eq('usuario_id', user.id)
        .eq('planejamento_id', planningId)
        .eq('tipo', 'tarefa')
        .eq('estado', 'ativo')
        .order('inicio_em');
    return rows
        .map(
          (row) => PlannedTask(
            blockId: row['id'] as String,
            occurrenceId: row['ocorrencia_tarefa_id'] as String,
            title: row['titulo'] as String? ?? 'Tarefa',
            start: DateTime.parse(row['inicio_em'] as String).toLocal(),
            end: DateTime.parse(row['fim_em'] as String).toLocal(),
          ),
        )
        .toList();
  }

  Future<ReplanningProposal> _loadProposal(
    Map<String, dynamic> row,
    List<PlannedTask> current,
  ) async {
    final user = _requireUser();
    final changes = await _client
        .from('alteracoes_proposta')
        .select('*,ocorrencias_tarefas(tarefas(titulo))')
        .eq('usuario_id', user.id)
        .eq('proposta_id', row['id'] as String);
    final suggested = <PlannedTask>[];
    for (final task in current) {
      final matching = changes.where(
        (change) => change['bloco_id'] == task.blockId,
      );
      if (matching.isEmpty) {
        suggested.add(task);
        continue;
      }
      final change = matching.first;
      if (change['acao'] == 'remover') continue;
      suggested.add(
        PlannedTask(
          blockId: task.blockId,
          changeId: change['id'] as String,
          occurrenceId: task.occurrenceId,
          title: task.title,
          start: DateTime.parse(change['novo_inicio_em'] as String).toLocal(),
          end: DateTime.parse(change['novo_fim_em'] as String).toLocal(),
        ),
      );
    }
    for (final change in changes.where((item) => item['acao'] == 'inserir')) {
      final occurrence = change['ocorrencias_tarefas'] as Map<String, dynamic>;
      final task = occurrence['tarefas'] as Map<String, dynamic>;
      suggested.add(
        PlannedTask(
          changeId: change['id'] as String,
          occurrenceId: change['ocorrencia_tarefa_id'] as String,
          title: task['titulo'] as String,
          start: DateTime.parse(change['novo_inicio_em'] as String).toLocal(),
          end: DateTime.parse(change['novo_fim_em'] as String).toLocal(),
        ),
      );
    }
    suggested.sort((a, b) => a.start.compareTo(b.start));
    return ReplanningProposal(
      id: row['id'] as String,
      planningId: row['planejamento_id'] as String,
      baseVersion: row['versao_base'] as int,
      state: ProposalState.pending,
      current: current,
      suggested: suggested,
      reason: row['motivo'] as String,
    );
  }

  Map<String, dynamic> _changeBase(
    String userId,
    String proposalId,
    String planningId,
    DateTime date,
  ) => {
    'usuario_id': userId,
    'proposta_id': proposalId,
    'planejamento_id': planningId,
    'data_local': _date(date),
  };

  PlanState _planState(String value) => switch (value) {
    'confirmado' => PlanState.confirmed,
    'encerrado' => PlanState.closed,
    _ => PlanState.provisional,
  };

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Sessão não encontrada.');
    return user;
  }

  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
