import 'package:flutter_test/flutter_test.dart';
import 'package:rotina/features/commitments/domain/models/daily_commitment.dart';
import 'package:rotina/features/commitments/domain/models/recurring_commitment.dart';

void main() {
  const source = RecurringCommitment(
    rowIdsByDay: {1: 'id'},
    title: 'Faculdade',
    type: CommitmentType.college,
    mandatory: true,
    startMinutes: 18 * 60,
    endMinutes: 21 * 60,
    commuteBeforeMinutes: 30,
    commuteAfterMinutes: 20,
    active: true,
  );

  test('detecta conflito diário considerando deslocamento', () {
    final first = DailyCommitment(
      source: source,
      date: DateTime(2026, 11, 23),
      start: DateTime(2026, 11, 23, 18),
      end: DateTime(2026, 11, 23, 21),
      changedForDate: false,
    );
    final second = DailyCommitment(
      source: source,
      date: DateTime(2026, 11, 23),
      start: DateTime(2026, 11, 23, 17, 40),
      end: DateTime(2026, 11, 23, 17, 50),
      changedForDate: true,
    );

    expect(first.conflictsWith(second), isTrue);
  });

  test('não acusa conflito entre horários separados', () {
    final first = DailyCommitment(
      source: source,
      date: DateTime(2026, 11, 23),
      start: DateTime(2026, 11, 23, 18),
      end: DateTime(2026, 11, 23, 21),
      changedForDate: false,
    );
    final second = DailyCommitment(
      source: source,
      date: DateTime(2026, 11, 23),
      start: DateTime(2026, 11, 23, 22),
      end: DateTime(2026, 11, 23, 23),
      changedForDate: false,
    );

    expect(first.conflictsWith(second), isFalse);
  });
}
