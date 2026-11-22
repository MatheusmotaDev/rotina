import 'package:flutter/foundation.dart';

import 'recurring_commitment.dart';

@immutable
class DailyCommitment {
  const DailyCommitment({
    required this.source,
    required this.date,
    required this.start,
    required this.end,
    required this.changedForDate,
  });

  final RecurringCommitment source;
  final DateTime date;
  final DateTime start;
  final DateTime end;
  final bool changedForDate;

  DateTime get occupiedStart =>
      start.subtract(Duration(minutes: source.commuteBeforeMinutes));

  DateTime get occupiedEnd =>
      end.add(Duration(minutes: source.commuteAfterMinutes));

  bool conflictsWith(DailyCommitment other) {
    if (!source.active || !other.source.active) return false;
    return occupiedStart.isBefore(other.occupiedEnd) &&
        other.occupiedStart.isBefore(occupiedEnd);
  }
}

enum CommitmentExceptionAction { defaultSchedule, cancelled, changed }
