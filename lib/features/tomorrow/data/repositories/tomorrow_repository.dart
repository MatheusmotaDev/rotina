import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../availability/domain/models/daily_availability.dart';
import '../../../availability/domain/services/availability_engine.dart';
import '../../../checkin/domain/models/daily_checkin.dart';
import '../../../commitments/data/repositories/commitments_repository.dart';
import '../../../commitments/domain/models/daily_commitment.dart';
import '../../../tasks/data/repositories/tasks_repository.dart';
import '../../../tasks/domain/models/task_item.dart';
import '../../domain/models/tomorrow_preparation.dart';

class TomorrowRepository {
  TomorrowRepository(this._client, this._commitments, this._tasks);

  final SupabaseClient _client;
  final CommitmentsRepository _commitments;
  final TasksRepository _tasks;

  Future<TomorrowPreparation> load() async {
    final user = _requireUser();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _client
          .from('perfis')
          .select('hora_acordar_padrao,hora_dormir_padrao,reserva_diaria_min')
          .eq('id', user.id)
          .single(),
      _client
          .from('preparacoes_dia_seguinte')
          .select()
          .eq('usuario_id', user.id)
          .eq('data_local', _date(tomorrow))
          .maybeSingle(),
      _commitments.loadForDate(tomorrow),
      _tasks.loadForDate(today),
    ]);
    final profile = results[0] as Map<String, dynamic>;
    final saved = results[1] as Map<String, dynamic>?;
    final dailyCommitments = (results[2] as List<dynamic>)
        .cast<DailyCommitment>();
    final todayTasks = (results[3] as List<dynamic>).cast<TaskItem>();
    final confirmations = _confirmationMap(saved?['compromissos_confirmados']);
    final wakeMinutes = _parseTime(
      saved?['acordar_pretendido'] as String? ??
          profile['hora_acordar_padrao'] as String,
    );
    final commitments = dailyCommitments.map((occurrence) {
      final id = occurrence.source.rowIdsByDay[tomorrow.weekday]!;
      return CheckinCommitment(
        id: id,
        title: occurrence.source.title,
        start: occurrence.occupiedStart,
        end: occurrence.occupiedEnd,
        confirmed: confirmations[id] ?? true,
      );
    }).toList();
    final pendingTasks = todayTasks
        .where(
          (task) =>
              task.status != TaskStatus.completed &&
              task.status != TaskStatus.cancelled,
        )
        .toList();

    return TomorrowPreparation(
      date: tomorrow,
      wakeMinutes: wakeMinutes,
      commitments: commitments,
      pendingTasks: pendingTasks,
      selectedTaskIds: const {},
      preview: _preview(
        date: tomorrow,
        wakeMinutes: wakeMinutes,
        sleepMinutes: _parseTime(profile['hora_dormir_padrao'] as String),
        reserveMinutes: profile['reserva_diaria_min'] as int,
        commitments: commitments,
      ),
      saved: saved != null,
    );
  }

  Future<void> save(TomorrowPreparation preparation) async {
    final user = _requireUser();
    await _client.from('preparacoes_dia_seguinte').upsert({
      'usuario_id': user.id,
      'data_local': _date(preparation.date),
      'acordar_pretendido': _time(preparation.wakeMinutes),
      'compromissos_confirmados': {
        for (final item in preparation.commitments) item.id: item.confirmed,
      },
      'atualizado_em': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'usuario_id,data_local');
    for (final task in preparation.pendingTasks) {
      if (preparation.selectedTaskIds.contains(task.id)) {
        await _tasks.reschedule(task, preparation.date);
      }
    }
  }

  Future<TomorrowPreparation> refreshPreview(
    TomorrowPreparation preparation,
  ) async {
    final user = _requireUser();
    final profile = await _client
        .from('perfis')
        .select('hora_dormir_padrao,reserva_diaria_min')
        .eq('id', user.id)
        .single();
    return preparation.copyWith(
      preview: _preview(
        date: preparation.date,
        wakeMinutes: preparation.wakeMinutes,
        sleepMinutes: _parseTime(profile['hora_dormir_padrao'] as String),
        reserveMinutes: profile['reserva_diaria_min'] as int,
        commitments: preparation.commitments,
      ),
    );
  }

  DailyAvailability _preview({
    required DateTime date,
    required int wakeMinutes,
    required int sleepMinutes,
    required int reserveMinutes,
    required List<CheckinCommitment> commitments,
  }) {
    final start = DateTime(
      date.year,
      date.month,
      date.day,
      wakeMinutes ~/ 60,
      wakeMinutes % 60,
    );
    var end = DateTime(
      date.year,
      date.month,
      date.day,
      sleepMinutes ~/ 60,
      sleepMinutes % 60,
    );
    if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
    return const AvailabilityEngine().calculate(
      AvailabilityInput(
        awakeStart: start,
        awakeEnd: end,
        busyIntervals: commitments
            .where((item) => item.confirmed)
            .map(
              (item) => TimeInterval(
                start: item.start,
                end: item.end,
                label: item.title,
              ),
            )
            .toList(),
        personalReserveMinutes: reserveMinutes,
        provisional: true,
      ),
    );
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Sessão não encontrada.');
    return user;
  }

  Map<String, bool> _confirmationMap(Object? value) {
    if (value is! Map) return const {};
    return value.map((key, confirmed) => MapEntry('$key', confirmed == true));
  }

  int _parseTime(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _time(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}:00';
  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
