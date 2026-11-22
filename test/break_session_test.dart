import 'package:flutter_test/flutter_test.dart';
import 'package:rotina/features/breaks/domain/models/break_session.dart';

void main() {
  test('calcula duração de uma pausa encerrada', () {
    final session = BreakSession(
      id: '1',
      startedAt: DateTime(2026, 11, 22, 10),
      endedAt: DateTime(2026, 11, 22, 10, 15),
      plannedMinutes: 15,
      reminderEnabled: true,
    );

    expect(session.elapsed(), const Duration(minutes: 15));
    expect(session.active, isFalse);
  });

  test('lembrete vence somente após a duração planejada', () {
    final session = BreakSession(
      id: '1',
      startedAt: DateTime(2026, 11, 22, 10),
      plannedMinutes: 15,
      reminderEnabled: true,
    );

    expect(session.reminderDue(DateTime(2026, 11, 22, 10, 14)), isFalse);
    expect(session.reminderDue(DateTime(2026, 11, 22, 10, 15)), isTrue);
  });
}
