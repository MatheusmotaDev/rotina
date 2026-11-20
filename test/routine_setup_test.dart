import 'package:flutter_test/flutter_test.dart';
import 'package:rotina/features/onboarding/domain/models/routine_setup.dart';

void main() {
  group('RoutineSetup', () {
    test('soma as reservas diárias', () {
      const setup = RoutineSetup(
        mealsMinutes: 90,
        restMinutes: 45,
        commuteMinutes: 60,
      );

      expect(setup.totalReserveMinutes, 195);
    });

    test('converte horários entre banco e minutos', () {
      final minutes = RoutineSetup.parseTime('18:30:00', fallback: 0);

      expect(minutes, 1110);
      expect(RoutineSetup.timeForDatabase(minutes), '18:30:00');
    });

    test('usa horário padrão quando o valor é inválido', () {
      expect(RoutineSetup.parseTime('inválido', fallback: 480), 480);
    });
  });
}
