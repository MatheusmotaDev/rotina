import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/activity_report.dart';
import '../../domain/services/report_feedback.dart';

class ReportsRepository {
  ReportsRepository(this._client);

  final SupabaseClient _client;

  Future<DailyActivityReport> loadDaily(DateTime date) async {
    final user = _requireUser();
    final localDate = DateTime(date.year, date.month, date.day);
    final dateValue = _date(localDate);
    final rangeStart = localDate.toUtc().toIso8601String();
    final rangeEnd = localDate
        .add(const Duration(days: 1))
        .toUtc()
        .toIso8601String();

    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _client
          .from('ocorrencias_tarefas')
          .select('estado,tarefas!inner(duracao_estimada_min)')
          .eq('usuario_id', user.id)
          .eq('data_local', dateValue),
      _client
          .from('sessoes_foco')
          .select('inicio_em,fim_em,duracao_pausada_seg,estado')
          .eq('usuario_id', user.id)
          .gte('inicio_em', rangeStart)
          .lt('inicio_em', rangeEnd),
      _client
          .from('pausas')
          .select('inicio_em,fim_em')
          .eq('usuario_id', user.id)
          .gte('inicio_em', rangeStart)
          .lt('inicio_em', rangeEnd),
      _client
          .from('checkins_diarios')
          .select('acordar_planejado,acordou_em')
          .eq('usuario_id', user.id)
          .eq('data_local', dateValue)
          .maybeSingle(),
      _client
          .from('perfis')
          .select('nivel_cobranca,hora_acordar_padrao')
          .eq('id', user.id)
          .single(),
    ]);

    final tasks = results[0] as List<dynamic>;
    final focus = results[1] as List<dynamic>;
    final breaks = results[2] as List<dynamic>;
    final checkin = results[3] as Map<String, dynamic>?;
    final profile = results[4] as Map<String, dynamic>;
    final completed = tasks.where((row) => row['estado'] == 'concluida').length;
    final postponed = tasks.where((row) => row['estado'] == 'adiada').length;
    final pending = tasks.length - completed - postponed;
    final estimated = tasks.fold<int>(0, (total, row) {
      final task = row['tarefas'] as Map<String, dynamic>;
      return total + (task['duracao_estimada_min'] as int);
    });

    return DailyActivityReport(
      date: localDate,
      completedTasks: completed,
      pendingTasks: pending,
      postponedTasks: postponed,
      estimatedMinutes: estimated,
      focusMinutes: focus.fold<int>(0, (total, row) {
        if (row['fim_em'] == null || row['estado'] != 'concluida') return total;
        final duration =
            DateTime.parse(row['fim_em'] as String)
                .difference(DateTime.parse(row['inicio_em'] as String))
                .inSeconds -
            (row['duracao_pausada_seg'] as int? ?? 0);
        return total + (duration ~/ 60);
      }),
      restMinutes: breaks.fold<int>(0, (total, row) {
        if (row['fim_em'] == null) return total;
        return total +
            DateTime.parse(row['fim_em'] as String)
                .difference(DateTime.parse(row['inicio_em'] as String))
                .inMinutes;
      }),
      plannedWakeMinutes: _parseTime(
        checkin?['acordar_planejado'] as String? ??
            profile['hora_acordar_padrao'] as String,
      ),
      actualWake: checkin == null
          ? null
          : DateTime.parse(checkin['acordou_em'] as String).toLocal(),
      feedback: const ReportFeedback().build(
        completed: completed,
        total: tasks.length,
        tone: profile['nivel_cobranca'] as String,
      ),
    );
  }

  Future<WeeklyActivityReport> loadWeek(DateTime endDate) async {
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final days = await Future.wait([
      for (var offset = 6; offset >= 0; offset--)
        loadDaily(end.subtract(Duration(days: offset))),
    ]);
    return WeeklyActivityReport(days: days);
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

  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
