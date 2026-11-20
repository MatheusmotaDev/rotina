import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/routine_setup.dart';

class OnboardingRepository {
  OnboardingRepository(this._client);

  final SupabaseClient _client;

  Future<RoutineSetup> load() async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Sessão não encontrada.');

    final profile = await _client
        .from('perfis')
        .select('hora_acordar_padrao,hora_dormir_padrao,reserva_diaria_min')
        .eq('id', user.id)
        .maybeSingle();
    final metadata = user.userMetadata ?? const <String, dynamic>{};

    return RoutineSetup(
      isStudent: metadata['estuda'] as bool? ?? false,
      isWorker: metadata['trabalha'] as bool? ?? false,
      objectives: _objectivesFrom(metadata['objetivos']),
      wakeMinutes: RoutineSetup.parseTime(
        profile?['hora_acordar_padrao'] as String?,
        fallback: 8 * 60,
      ),
      sleepMinutes: RoutineSetup.parseTime(
        profile?['hora_dormir_padrao'] as String?,
        fallback: 23 * 60,
      ),
      mealsMinutes: _intFrom(metadata['refeicoes_min'], fallback: 90),
      restMinutes: _intFrom(metadata['descanso_min'], fallback: 60),
      commuteMinutes: _intFrom(
        metadata['deslocamento_min'],
        fallback: _commuteFallback(profile),
      ),
    );
  }

  Future<void> save(RoutineSetup setup) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Sessão não encontrada.');

    await _client
        .from('perfis')
        .update({
          'hora_acordar_padrao': RoutineSetup.timeForDatabase(
            setup.wakeMinutes,
          ),
          'hora_dormir_padrao': RoutineSetup.timeForDatabase(
            setup.sleepMinutes,
          ),
          'reserva_diaria_min': setup.totalReserveMinutes,
        })
        .eq('id', user.id);

    await _client.auth.updateUser(
      UserAttributes(
        data: {
          'onboarding_concluido': true,
          'estuda': setup.isStudent,
          'trabalha': setup.isWorker,
          'objetivos': setup.objectives.toList()..sort(),
          'refeicoes_min': setup.mealsMinutes,
          'descanso_min': setup.restMinutes,
          'deslocamento_min': setup.commuteMinutes,
        },
      ),
    );
  }

  Set<String> _objectivesFrom(Object? value) {
    if (value is List) {
      final values = value.whereType<String>().toSet();
      if (values.isNotEmpty) return values;
    }
    return const {'organização'};
  }

  int _intFrom(Object? value, {required int fallback}) {
    return value is num ? value.toInt() : fallback;
  }

  int _commuteFallback(Map<String, dynamic>? profile) {
    final total = profile?['reserva_diaria_min'];
    if (total is! num) return 60;
    return (total.toInt() - 150).clamp(0, 240).toInt();
  }
}
