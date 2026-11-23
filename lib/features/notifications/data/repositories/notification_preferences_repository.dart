import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/notification_preferences.dart';

class NotificationPreferencesRepository {
  NotificationPreferencesRepository(this._client);

  final SupabaseClient _client;

  Future<NotificationPreferences> load() async {
    final user = _requireUser();
    final row = await _client
        .from('preferencias_notificacoes')
        .select()
        .eq('usuario_id', user.id)
        .maybeSingle();
    if (row == null) return const NotificationPreferences.defaults();
    return NotificationPreferences(
      checkin: row['checkin'] as bool,
      taskStarts: row['inicio_tarefas'] as bool,
      commitments: row['compromissos'] as bool,
      breakEnd: row['fim_pausa'] as bool,
      nightlySummary: row['resumo_noturno'] as bool,
      checkinMinutes: _parseTime(row['hora_checkin'] as String),
      nightlyMinutes: _parseTime(row['hora_resumo_noturno'] as String),
      leadMinutes: row['antecedencia_inicio_min'] as int,
    );
  }

  Future<void> save(NotificationPreferences value) async {
    final user = _requireUser();
    await _client.from('preferencias_notificacoes').upsert({
      'usuario_id': user.id,
      'checkin': value.checkin,
      'inicio_tarefas': value.taskStarts,
      'compromissos': value.commitments,
      'fim_pausa': value.breakEnd,
      'resumo_noturno': value.nightlySummary,
      'hora_checkin': _time(value.checkinMinutes),
      'hora_resumo_noturno': _time(value.nightlyMinutes),
      'antecedencia_inicio_min': value.leadMinutes,
      'atualizado_em': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'usuario_id');
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Sessão não encontrada.');
    return user;
  }

  int _parseTime(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _time(int value) =>
      '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}:00';
}
