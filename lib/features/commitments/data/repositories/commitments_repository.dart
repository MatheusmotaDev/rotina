import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/daily_commitment.dart';
import '../../domain/models/recurring_commitment.dart';

class CommitmentsRepository {
  CommitmentsRepository(this._client);

  final SupabaseClient _client;

  Future<List<RecurringCommitment>> load() async {
    final user = _requireUser();
    final rows = await _client
        .from('compromissos_recorrentes')
        .select()
        .eq('usuario_id', user.id)
        .order('hora_inicio');

    final groups = <String, List<Map<String, dynamic>>>{};
    for (final rawRow in rows) {
      final row = Map<String, dynamic>.from(rawRow);
      groups.putIfAbsent(_groupKey(row), () => []).add(row);
    }

    return groups.values.map(_fromRows).toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
  }

  Future<void> create({
    required String title,
    required CommitmentType type,
    required Set<int> weekdays,
    required int startMinutes,
    required int endMinutes,
    required int commuteBeforeMinutes,
    required int commuteAfterMinutes,
  }) async {
    final user = _requireUser();
    await _client
        .from('compromissos_recorrentes')
        .insert(
          weekdays
              .map(
                (day) => _rowPayload(
                  userId: user.id,
                  day: day,
                  title: title,
                  type: type,
                  startMinutes: startMinutes,
                  endMinutes: endMinutes,
                  commuteBeforeMinutes: commuteBeforeMinutes,
                  commuteAfterMinutes: commuteAfterMinutes,
                  active: true,
                ),
              )
              .toList(),
        );
  }

  Future<void> update(
    RecurringCommitment commitment, {
    required String title,
    required CommitmentType type,
    required Set<int> weekdays,
    required int startMinutes,
    required int endMinutes,
    required int commuteBeforeMinutes,
    required int commuteAfterMinutes,
  }) async {
    final user = _requireUser();
    final existingDays = commitment.weekdays;
    final removedDays = existingDays.difference(weekdays);
    final retainedDays = existingDays.intersection(weekdays);
    final addedDays = weekdays.difference(existingDays);

    final removedIds = removedDays.map((day) => commitment.rowIdsByDay[day]!);
    if (removedIds.isNotEmpty) {
      await _client
          .from('compromissos_recorrentes')
          .delete()
          .eq('usuario_id', user.id)
          .inFilter('id', removedIds.toList());
    }

    final commonChanges = {
      'titulo': title.trim(),
      'tipo': _typeForDatabase(type),
      'hora_inicio': RecurringCommitment.timeForDatabase(startMinutes),
      'hora_fim': RecurringCommitment.timeForDatabase(endMinutes),
      'deslocamento_antes_min': commuteBeforeMinutes,
      'deslocamento_depois_min': commuteAfterMinutes,
    };
    for (final day in retainedDays) {
      await _client
          .from('compromissos_recorrentes')
          .update(commonChanges)
          .eq('usuario_id', user.id)
          .eq('id', commitment.rowIdsByDay[day]!);
    }

    if (addedDays.isNotEmpty) {
      await _client
          .from('compromissos_recorrentes')
          .insert(
            addedDays
                .map(
                  (day) => _rowPayload(
                    userId: user.id,
                    day: day,
                    title: title,
                    type: type,
                    startMinutes: startMinutes,
                    endMinutes: endMinutes,
                    commuteBeforeMinutes: commuteBeforeMinutes,
                    commuteAfterMinutes: commuteAfterMinutes,
                    active: commitment.active,
                  ),
                )
                .toList(),
          );
    }
  }

  Future<void> setActive(RecurringCommitment commitment, bool active) async {
    final user = _requireUser();
    await _client
        .from('compromissos_recorrentes')
        .update({'ativo': active})
        .eq('usuario_id', user.id)
        .inFilter('id', commitment.rowIds.toList());
  }

  Future<void> delete(RecurringCommitment commitment) async {
    final user = _requireUser();
    await _client
        .from('compromissos_recorrentes')
        .delete()
        .eq('usuario_id', user.id)
        .inFilter('id', commitment.rowIds.toList());
  }

  Future<List<DailyCommitment>> loadForDate(DateTime date) async {
    final user = _requireUser();
    final day = DateTime(date.year, date.month, date.day);
    final previousDay = day.subtract(const Duration(days: 1));
    final commitments = await load();
    final exceptions = await _client
        .from('excecoes_compromissos')
        .select()
        .eq('usuario_id', user.id)
        .gte('data_local', _dateForDatabase(previousDay))
        .lte('data_local', _dateForDatabase(day));
    final exceptionsByKey = <String, Map<String, dynamic>>{
      for (final raw in exceptions)
        '${raw['compromisso_id']}|${raw['data_local']}':
            Map<String, dynamic>.from(raw),
    };

    final occurrences = <DailyCommitment>[];
    for (final commitment in commitments.where((item) => item.active)) {
      for (final occurrenceDate in [previousDay, day]) {
        final weekday = occurrenceDate.weekday;
        final rowId = commitment.rowIdsByDay[weekday];
        if (rowId == null) continue;
        final exception =
            exceptionsByKey['$rowId|${_dateForDatabase(occurrenceDate)}'];
        final occurrence = _dailyOccurrence(
          commitment,
          occurrenceDate,
          exception,
        );
        if (occurrence == null) continue;
        final dayEnd = day.add(const Duration(days: 1));
        if (occurrence.end.isAfter(day) && occurrence.start.isBefore(dayEnd)) {
          occurrences.add(occurrence);
        }
      }
    }
    occurrences.sort((a, b) => a.start.compareTo(b.start));
    return occurrences;
  }

  Future<void> saveException({
    required RecurringCommitment commitment,
    required DateTime date,
    required CommitmentExceptionAction action,
    int? changedStartMinutes,
    int? changedEndMinutes,
  }) async {
    final user = _requireUser();
    final localDate = DateTime(date.year, date.month, date.day);
    final rowId = commitment.rowIdsByDay[localDate.weekday];
    if (rowId == null) {
      throw ArgumentError('O compromisso não acontece na data escolhida.');
    }

    if (action == CommitmentExceptionAction.defaultSchedule) {
      await _client
          .from('excecoes_compromissos')
          .delete()
          .eq('usuario_id', user.id)
          .eq('compromisso_id', rowId)
          .eq('data_local', _dateForDatabase(localDate));
      return;
    }

    DateTime? changedStart;
    DateTime? changedEnd;
    if (action == CommitmentExceptionAction.changed) {
      if (changedStartMinutes == null || changedEndMinutes == null) {
        throw ArgumentError('Informe os novos horários.');
      }
      changedStart = _dateTimeAt(localDate, changedStartMinutes);
      changedEnd = _dateTimeAt(localDate, changedEndMinutes);
      if (!changedEnd.isAfter(changedStart)) {
        changedEnd = changedEnd.add(const Duration(days: 1));
      }
    }

    await _client.from('excecoes_compromissos').upsert({
      'usuario_id': user.id,
      'compromisso_id': rowId,
      'data_local': _dateForDatabase(localDate),
      'situacao': action == CommitmentExceptionAction.cancelled
          ? 'cancelado'
          : 'alterado',
      'inicio_ajustado_em': changedStart?.toUtc().toIso8601String(),
      'fim_ajustado_em': changedEnd?.toUtc().toIso8601String(),
    }, onConflict: 'usuario_id,compromisso_id,data_local');
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Sessão não encontrada.');
    return user;
  }

  DailyCommitment? _dailyOccurrence(
    RecurringCommitment commitment,
    DateTime date,
    Map<String, dynamic>? exception,
  ) {
    if (exception?['situacao'] == 'cancelado') return null;
    if (exception?['situacao'] == 'alterado') {
      return DailyCommitment(
        source: commitment,
        date: date,
        start: DateTime.parse(exception!['inicio_ajustado_em'] as String)
            .toLocal(),
        end: DateTime.parse(exception['fim_ajustado_em'] as String).toLocal(),
        changedForDate: true,
      );
    }

    final start = _dateTimeAt(date, commitment.startMinutes);
    var end = _dateTimeAt(date, commitment.endMinutes);
    if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
    return DailyCommitment(
      source: commitment,
      date: date,
      start: start,
      end: end,
      changedForDate: false,
    );
  }

  DateTime _dateTimeAt(DateTime date, int minutes) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      minutes ~/ 60,
      minutes % 60,
    );
  }

  String _dateForDatabase(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Map<String, dynamic> _rowPayload({
    required String userId,
    required int day,
    required String title,
    required CommitmentType type,
    required int startMinutes,
    required int endMinutes,
    required int commuteBeforeMinutes,
    required int commuteAfterMinutes,
    required bool active,
  }) {
    return {
      'usuario_id': userId,
      'titulo': title.trim(),
      'tipo': _typeForDatabase(type),
      'dia_semana': day,
      'hora_inicio': RecurringCommitment.timeForDatabase(startMinutes),
      'hora_fim': RecurringCommitment.timeForDatabase(endMinutes),
      'deslocamento_antes_min': commuteBeforeMinutes,
      'deslocamento_depois_min': commuteAfterMinutes,
      'ativo': active,
    };
  }

  RecurringCommitment _fromRows(List<Map<String, dynamic>> rows) {
    final first = rows.first;
    return RecurringCommitment(
      rowIdsByDay: {
        for (final row in rows) row['dia_semana'] as int: row['id'] as String,
      },
      title: first['titulo'] as String,
      type: _typeFromDatabase(first['tipo'] as String),
      startMinutes: RecurringCommitment.parseTime(
        first['hora_inicio'] as String,
      ),
      endMinutes: RecurringCommitment.parseTime(first['hora_fim'] as String),
      commuteBeforeMinutes: first['deslocamento_antes_min'] as int,
      commuteAfterMinutes: first['deslocamento_depois_min'] as int,
      active: first['ativo'] as bool,
    );
  }

  String _groupKey(Map<String, dynamic> row) {
    return [
      row['titulo'],
      row['tipo'],
      row['hora_inicio'],
      row['hora_fim'],
      row['deslocamento_antes_min'],
      row['deslocamento_depois_min'],
      row['ativo'],
    ].join('|');
  }

  String _typeForDatabase(CommitmentType type) => switch (type) {
    CommitmentType.work => 'trabalho',
    CommitmentType.college => 'faculdade',
    CommitmentType.other => 'outro',
  };

  CommitmentType _typeFromDatabase(String type) => switch (type) {
    'trabalho' => CommitmentType.work,
    'faculdade' => CommitmentType.college,
    _ => CommitmentType.other,
  };
}
