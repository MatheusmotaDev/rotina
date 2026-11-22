import 'package:flutter_test/flutter_test.dart';
import 'package:rotina/features/availability/domain/models/daily_availability.dart';
import 'package:rotina/features/tomorrow/domain/models/tomorrow_preparation.dart';

void main() {
  test('alteração preserva dados e invalida confirmação', () {
    final preparation = TomorrowPreparation(
      date: DateTime(2026, 11, 23),
      wakeMinutes: 480,
      commitments: const [],
      pendingTasks: const [],
      selectedTaskIds: const {},
      preview: DailyAvailability(
        awakeStart: DateTime(2026, 11, 23, 8),
        awakeEnd: DateTime(2026, 11, 23, 23),
        awakeMinutes: 900,
        busyMinutes: 0,
        personalReserveMinutes: 0,
        availableMinutes: 900,
        freePercentage: 100,
        freeWindows: const [],
        hasConflicts: false,
        overloaded: false,
        provisional: true,
      ),
      saved: true,
    );

    final changed = preparation.copyWith(wakeMinutes: 540, saved: false);
    expect(changed.wakeMinutes, 540);
    expect(changed.date, preparation.date);
    expect(changed.saved, isFalse);
    expect(changed.preview.provisional, isTrue);
  });
}
