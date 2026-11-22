import 'package:flutter_test/flutter_test.dart';
import 'package:rotina/features/availability/domain/models/personal_reservation.dart';

void main() {
  test('reserva se aplica somente aos dias selecionados', () {
    const reservation = PersonalReservation(
      id: '1',
      title: 'Almoço',
      weekdays: {DateTime.monday, DateTime.wednesday},
      startMinutes: 12 * 60,
      endMinutes: 13 * 60,
      active: true,
    );

    expect(reservation.appliesTo(DateTime(2026, 11, 23)), isTrue);
    expect(reservation.appliesTo(DateTime(2026, 11, 24)), isFalse);
  });

  test('reserva pode atravessar a meia-noite', () {
    const reservation = PersonalReservation(
      id: '1',
      title: 'Descanso',
      weekdays: {DateTime.monday},
      startMinutes: 23 * 60,
      endMinutes: 30,
      active: true,
    );
    final date = DateTime(2026, 11, 23);

    expect(
      reservation.endAt(date).difference(reservation.startAt(date)),
      const Duration(minutes: 90),
    );
  });
}
