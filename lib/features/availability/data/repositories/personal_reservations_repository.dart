import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/personal_reservation.dart';

class PersonalReservationsRepository {
  PersonalReservationsRepository(this._client);

  final SupabaseClient _client;

  Future<List<PersonalReservation>> loadAll() async {
    final user = _requireUser();
    final rows = await _client
        .from('reservas_pessoais')
        .select()
        .eq('usuario_id', user.id)
        .order('hora_inicio');
    return rows.map(_fromRow).toList();
  }

  Future<void> create({
    required String title,
    required Set<int> weekdays,
    required int startMinutes,
    required int endMinutes,
  }) async {
    final user = _requireUser();
    await _client.from('reservas_pessoais').insert({
      'usuario_id': user.id,
      'titulo': title.trim(),
      'dias_semana': weekdays.toList()..sort(),
      'hora_inicio': _time(startMinutes),
      'hora_fim': _time(endMinutes),
    });
  }

  Future<void> delete(String id) async {
    final user = _requireUser();
    await _client
        .from('reservas_pessoais')
        .delete()
        .eq('usuario_id', user.id)
        .eq('id', id);
  }

  PersonalReservation _fromRow(Map<String, dynamic> row) => PersonalReservation(
    id: row['id'] as String,
    title: row['titulo'] as String,
    weekdays: (row['dias_semana'] as List).cast<int>().toSet(),
    startMinutes: _parseTime(row['hora_inicio'] as String),
    endMinutes: _parseTime(row['hora_fim'] as String),
    active: row['ativo'] as bool,
  );

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Sessão não encontrada.');
    return user;
  }

  int _parseTime(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _time(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}:00';
}
