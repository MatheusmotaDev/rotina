import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/break_session.dart';

class BreaksRepository {
  BreaksRepository(this._client);

  final SupabaseClient _client;

  Future<List<BreakSession>> loadRecent() async {
    final user = _requireUser();
    final rows = await _client
        .from('pausas')
        .select()
        .eq('usuario_id', user.id)
        .order('inicio_em', ascending: false)
        .limit(30);
    return rows.map(_fromRow).toList();
  }

  Future<void> start({
    required int plannedMinutes,
    required bool reminderEnabled,
  }) async {
    final user = _requireUser();
    await _client.from('pausas').insert({
      'usuario_id': user.id,
      'tipo': 'espontanea',
      'inicio_em': DateTime.now().toUtc().toIso8601String(),
      'duracao_planejada_min': plannedMinutes,
      'lembrete_ativo': reminderEnabled,
    });
  }

  Future<void> finish(BreakSession session) async {
    final user = _requireUser();
    await _client
        .from('pausas')
        .update({'fim_em': DateTime.now().toUtc().toIso8601String()})
        .eq('usuario_id', user.id)
        .eq('id', session.id);
  }

  BreakSession _fromRow(Map<String, dynamic> row) => BreakSession(
    id: row['id'] as String,
    startedAt: DateTime.parse(row['inicio_em'] as String).toLocal(),
    endedAt: row['fim_em'] == null
        ? null
        : DateTime.parse(row['fim_em'] as String).toLocal(),
    plannedMinutes: row['duracao_planejada_min'] as int?,
    reminderEnabled: row['lembrete_ativo'] as bool? ?? false,
  );

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Sessão não encontrada.');
    return user;
  }
}
