import 'package:flutter_test/flutter_test.dart';
import 'package:rotina/features/commitments/domain/models/recurring_commitment.dart';

void main() {
  RecurringCommitment commitment({
    required int day,
    required int start,
    required int end,
    int before = 0,
    int after = 0,
    bool active = true,
  }) {
    return RecurringCommitment(
      rowIdsByDay: {day: 'id-$day-$start'},
      title: 'Compromisso',
      type: CommitmentType.other,
      mandatory: true,
      startMinutes: start,
      endMinutes: end,
      commuteBeforeMinutes: before,
      commuteAfterMinutes: after,
      active: active,
    );
  }

  group('conflitos de compromissos', () {
    test('detecta sobreposição no mesmo dia', () {
      final first = commitment(day: 1, start: 8 * 60, end: 10 * 60);
      final second = commitment(day: 1, start: 9 * 60, end: 11 * 60);

      expect(first.conflictsWith(second), isTrue);
    });

    test('considera o deslocamento na ocupação', () {
      final first = commitment(day: 2, start: 9 * 60, end: 10 * 60, before: 30);
      final second = commitment(day: 2, start: 8 * 60, end: 8 * 60 + 45);

      expect(first.conflictsWith(second), isTrue);
    });

    test('detecta conflito depois da meia-noite', () {
      final overnight = commitment(day: 5, start: 23 * 60, end: 60);
      final saturday = commitment(day: 6, start: 30, end: 90);

      expect(overnight.conflictsWith(saturday), isTrue);
    });

    test('ignora compromissos desativados', () {
      final inactive = commitment(
        day: 1,
        start: 8 * 60,
        end: 10 * 60,
        active: false,
      );
      final active = commitment(day: 1, start: 9 * 60, end: 11 * 60);

      expect(inactive.conflictsWith(active), isFalse);
    });
  });
}
