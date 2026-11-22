import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../commitments/data/repositories/commitments_repository.dart';
import '../../domain/models/daily_checkin.dart';

class CheckinRepository {
  CheckinRepository(this._client, this._commitmentsRepository);

  final SupabaseClient _client;
  final CommitmentsRepository _commitmentsRepository;

  Future<DailyCheckin> loadToday() async {
    final user = _requireUser();
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);
    final dateValue = _dateForDatabase(date);
    final profile = await _client
        .from('perfis')
        .select('hora_acordar_padrao')
        .eq('id', user.id)
        .single();
    final existing = await _client
        .from('checkins_diarios')
        .select()
        .eq('usuario_id', user.id)
        .eq('data_local', dateValue)
        .maybeSingle();
    final dailyCommitments = await _commitmentsRepository.loadForDate(date);
    final confirmations = _confirmationMap(
      existing?['compromissos_confirmados'],
    );
    final commitments = dailyCommitments.map((occurrence) {
      final id = occurrence.source.rowIdsByDay[occurrence.date.weekday]!;
      return CheckinCommitment(
        id: id,
        title: occurrence.source.title,
        start: occurrence.start,
        end: occurrence.end,
        confirmed: confirmations[id] ?? true,
      );
    }).toList();

    final plannedValue =
        existing?['acordar_planejado'] as String? ??
        profile['hora_acordar_padrao'] as String;
    final plannedMinutes = _parseTime(plannedValue);
    return DailyCheckin(
      date: date,
      plannedWakeMinutes: plannedMinutes,
      actualWake: existing == null
          ? now
          : DateTime.parse(existing['acordou_em'] as String).toLocal(),
      energy: _energyFromDatabase(existing?['disposicao'] as String?),
      commitments: commitments,
      completed: existing != null,
      observation: existing?['observacao'] as String? ?? '',
    );
  }

  Future<void> save(DailyCheckin checkin) async {
    final user = _requireUser();
    await _client.from('checkins_diarios').upsert({
      'usuario_id': user.id,
      'data_local': _dateForDatabase(checkin.date),
      'acordou_em': checkin.actualWake.toUtc().toIso8601String(),
      'acordar_planejado': _timeForDatabase(checkin.plannedWakeMinutes),
      'disposicao': _energyForDatabase(checkin.energy),
      'compromissos_confirmados': {
        for (final item in checkin.commitments) item.id: item.confirmed,
      },
      'observacao': checkin.observation.trim().isEmpty
          ? null
          : checkin.observation.trim(),
    }, onConflict: 'usuario_id,data_local');
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Sessão não encontrada.');
    return user;
  }

  Map<String, bool> _confirmationMap(Object? value) {
    if (value is! Map) return const {};
    return value.map(
      (key, confirmed) => MapEntry(key.toString(), confirmed == true),
    );
  }

  EnergyLevel _energyFromDatabase(String? value) => switch (value) {
    'baixa' => EnergyLevel.low,
    'alta' => EnergyLevel.high,
    _ => EnergyLevel.normal,
  };

  String _energyForDatabase(EnergyLevel value) => switch (value) {
    EnergyLevel.low => 'baixa',
    EnergyLevel.normal => 'normal',
    EnergyLevel.high => 'alta',
  };

  int _parseTime(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _timeForDatabase(int minutes) {
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  String _dateForDatabase(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
