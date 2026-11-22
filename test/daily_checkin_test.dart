import 'package:flutter_test/flutter_test.dart';
import 'package:rotina/features/checkin/domain/models/daily_checkin.dart';

void main() {
  DailyCheckin checkinAt(int hour, int minute) {
    return DailyCheckin(
      date: DateTime(2026, 11, 21),
      plannedWakeMinutes: 8 * 60,
      actualWake: DateTime(2026, 11, 21, hour, minute),
      energy: EnergyLevel.normal,
      commitments: const [],
      completed: false,
    );
  }

  test('calcula atraso em relação ao despertar planejado', () {
    expect(checkinAt(10, 0).wakeDifferenceMinutes, 120);
  });

  test('calcula despertar antecipado com valor negativo', () {
    expect(checkinAt(7, 30).wakeDifferenceMinutes, -30);
  });

  test('atualiza confirmação sem alterar os outros dados', () {
    final original = DailyCheckin(
      date: DateTime(2026, 11, 21),
      plannedWakeMinutes: 480,
      actualWake: DateTime(2026, 11, 21, 8),
      energy: EnergyLevel.high,
      commitments: [
        CheckinCommitment(
          id: 'faculdade',
          title: 'Faculdade',
          start: DateTime(2026, 11, 21, 18),
          end: DateTime(2026, 11, 21, 21),
          confirmed: true,
        ),
      ],
      completed: false,
    );

    final updated = original.copyWith(
      commitments: [original.commitments.first.copyWith(confirmed: false)],
    );

    expect(updated.commitments.single.confirmed, isFalse);
    expect(updated.energy, EnergyLevel.high);
  });
}
