import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/focus_session.dart';

class FocusRepository {
  FocusRepository(this._client);

  final SupabaseClient _client;

  Future<FocusSession?> loadActive() async {
    final user = _requireUser();
    final rows = await _client
        .from('sessoes_foco')
        .select()
        .eq('usuario_id', user.id)
        .inFilter('estado', ['em_andamento', 'pausada'])
        .order('inicio_em', ascending: false)
        .limit(1);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  Future<FocusSession> start({
    required FocusMode mode,
    String? taskOccurrenceId,
    int? plannedMinutes,
  }) async {
    final user = _requireUser();
    final row = await _client
        .from('sessoes_foco')
        .insert({
          'usuario_id': user.id,
          'ocorrencia_tarefa_id': taskOccurrenceId,
          'modo': mode == FocusMode.pomodoro ? 'pomodoro' : 'livre',
          'duracao_planejada_min': mode == FocusMode.pomodoro
              ? plannedMinutes
              : null,
          'inicio_em': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();
    return _fromRow(row);
  }

  Future<FocusSession> pause(FocusSession session) async {
    final row = await _update(session.id, {
      'estado': 'pausada',
      'pausada_em': DateTime.now().toUtc().toIso8601String(),
    });
    return _fromRow(row);
  }

  Future<FocusSession> resume(FocusSession session) async {
    final pausedAt = session.pausedAt;
    final extra = pausedAt == null
        ? 0
        : DateTime.now().difference(pausedAt).inSeconds;
    final row = await _update(session.id, {
      'estado': 'em_andamento',
      'pausada_em': null,
      'duracao_pausada_seg': session.pausedSeconds + extra,
    });
    return _fromRow(row);
  }

  Future<FocusSession> finish(
    FocusSession session, {
    bool cancelled = false,
  }) async {
    final now = DateTime.now();
    final activePause = session.pausedAt == null
        ? 0
        : now.difference(session.pausedAt!).inSeconds;
    final row = await _update(session.id, {
      'estado': cancelled ? 'cancelada' : 'concluida',
      'fim_em': now.toUtc().toIso8601String(),
      'pausada_em': null,
      'duracao_pausada_seg': session.pausedSeconds + activePause,
    });
    return _fromRow(row);
  }

  Future<Map<String, dynamic>> _update(
    String id,
    Map<String, dynamic> values,
  ) async {
    final user = _requireUser();
    return _client
        .from('sessoes_foco')
        .update(values)
        .eq('usuario_id', user.id)
        .eq('id', id)
        .select()
        .single();
  }

  FocusSession _fromRow(Map<String, dynamic> row) => FocusSession(
    id: row['id'] as String,
    taskOccurrenceId: row['ocorrencia_tarefa_id'] as String?,
    mode: row['modo'] == 'pomodoro' ? FocusMode.pomodoro : FocusMode.free,
    state: switch (row['estado'] as String) {
      'pausada' => FocusSessionState.paused,
      'concluida' => FocusSessionState.completed,
      'cancelada' => FocusSessionState.cancelled,
      _ => FocusSessionState.running,
    },
    startedAt: DateTime.parse(row['inicio_em'] as String).toLocal(),
    endedAt: row['fim_em'] == null
        ? null
        : DateTime.parse(row['fim_em'] as String).toLocal(),
    pausedAt: row['pausada_em'] == null
        ? null
        : DateTime.parse(row['pausada_em'] as String).toLocal(),
    pausedSeconds: row['duracao_pausada_seg'] as int? ?? 0,
    plannedMinutes: row['duracao_planejada_min'] as int?,
  );

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Sessão não encontrada.');
    return user;
  }
}
