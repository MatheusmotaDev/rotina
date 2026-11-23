import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show DateTimeComponents;

import '../../../commitments/data/repositories/commitments_repository.dart';
import '../../domain/models/notification_preferences.dart';
import '../../domain/services/notification_time.dart';
import '../repositories/notification_preferences_repository.dart';
import 'local_notification_service.dart';

class NotificationScheduler {
  NotificationScheduler(this._client, this._service);

  final SupabaseClient _client;
  final LocalNotificationService _service;

  Future<void> sync() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    final preferences = await NotificationPreferencesRepository(_client).load();
    final profile = await _client
        .from('perfis')
        .select('fuso_horario')
        .eq('id', user.id)
        .single();
    await _service.useTimezone(profile['fuso_horario'] as String);
    await _service.cancelAll();
    final now = DateTime.now();

    if (preferences.checkin) {
      await _service.schedule(
        id: 1001,
        title: 'Check-in da manhã',
        body: 'Conte como o seu dia começou para atualizar a disponibilidade.',
        date: const NotificationTime().nextDaily(
          now,
          preferences.checkinMinutes,
        ),
        payload: 'checkin',
        repeat: DateTimeComponents.time,
      );
    }
    if (preferences.nightlySummary) {
      await _service.schedule(
        id: 1002,
        title: 'Prepare o próximo dia',
        body: 'Revise as pendências e confirme a rotina de amanhã.',
        date: const NotificationTime().nextDaily(
          now,
          preferences.nightlyMinutes,
        ),
        payload: 'tomorrow',
        repeat: DateTimeComponents.time,
      );
    }
    if (preferences.taskStarts) {
      await _scheduleTasks(user.id, preferences, now);
    }
    if (preferences.commitments) {
      await _scheduleCommitments(preferences, now);
    }
    if (preferences.breakEnd) {
      await _scheduleActiveBreak(user.id, now);
    }
  }

  Future<void> _scheduleTasks(
    String userId,
    NotificationPreferences preferences,
    DateTime now,
  ) async {
    final end = now.add(const Duration(days: 7));
    final rows = await _client
        .from('blocos_agenda')
        .select('id,titulo,inicio_em,planejamentos_diarios!inner(estado)')
        .eq('usuario_id', userId)
        .eq('estado', 'ativo')
        .eq('planejamentos_diarios.estado', 'confirmado')
        .gte('inicio_em', now.toUtc().toIso8601String())
        .lt('inicio_em', end.toUtc().toIso8601String());
    for (final row in rows) {
      final start = DateTime.parse(row['inicio_em'] as String).toLocal();
      await _service.schedule(
        id: _id('task-${row['id']}'),
        title: 'Tarefa em breve',
        body:
            '${row['titulo'] ?? 'Sua tarefa'} começa em ${preferences.leadMinutes} min.',
        date: start.subtract(Duration(minutes: preferences.leadMinutes)),
        payload: 'planning',
      );
    }
  }

  Future<void> _scheduleCommitments(
    NotificationPreferences preferences,
    DateTime now,
  ) async {
    final repository = CommitmentsRepository(_client);
    final firstDate = DateTime(now.year, now.month, now.day);
    for (var offset = 0; offset < 7; offset++) {
      final date = firstDate.add(Duration(days: offset));
      final commitments = await repository.loadForDate(date);
      for (final commitment in commitments) {
        final reminder = commitment.start.subtract(
          Duration(minutes: preferences.leadMinutes),
        );
        await _service.schedule(
          id: _id(
            'commitment-${commitment.source.rowIdsByDay[date.weekday]}-${_date(date)}',
          ),
          title: 'Compromisso em breve',
          body:
              '${commitment.source.title} começa em ${preferences.leadMinutes} min.',
          date: reminder,
          payload: 'planning',
        );
      }
    }
  }

  Future<void> _scheduleActiveBreak(String userId, DateTime now) async {
    final row = await _client
        .from('pausas')
        .select('id,inicio_em,duracao_planejada_min,lembrete_ativo')
        .eq('usuario_id', userId)
        .isFilter('fim_em', null)
        .maybeSingle();
    if (row == null ||
        row['duracao_planejada_min'] == null ||
        row['lembrete_ativo'] != true) {
      return;
    }
    final end = DateTime.parse(row['inicio_em'] as String)
        .toLocal()
        .add(Duration(minutes: row['duracao_planejada_min'] as int));
    if (!end.isAfter(now)) return;
    await _service.schedule(
      id: _id('break-${row['id']}'),
      title: 'Pausa concluída',
      body: 'O tempo de descanso planejado terminou.',
      date: end,
      payload: 'break',
    );
  }

  int _id(String value) => value.codeUnits.fold<int>(
    17,
    (hash, unit) => (hash * 31 + unit) & 0x7fffffff,
  );
  String _date(DateTime value) => '${value.year}-${value.month}-${value.day}';
}
