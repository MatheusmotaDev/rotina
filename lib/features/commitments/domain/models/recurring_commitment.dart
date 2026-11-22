import 'package:flutter/foundation.dart';

enum CommitmentType { work, college, other }

@immutable
class RecurringCommitment {
  const RecurringCommitment({
    required this.rowIdsByDay,
    required this.title,
    required this.type,
    required this.mandatory,
    required this.startMinutes,
    required this.endMinutes,
    required this.commuteBeforeMinutes,
    required this.commuteAfterMinutes,
    required this.active,
  });

  final Map<int, String> rowIdsByDay;
  final String title;
  final CommitmentType type;
  final bool mandatory;
  final int startMinutes;
  final int endMinutes;
  final int commuteBeforeMinutes;
  final int commuteAfterMinutes;
  final bool active;

  Set<int> get weekdays => rowIdsByDay.keys.toSet();

  Iterable<String> get rowIds => rowIdsByDay.values;

  int get occupiedStartMinutes => startMinutes - commuteBeforeMinutes;

  int get occupiedEndMinutes {
    final adjustedEnd = endMinutes <= startMinutes
        ? endMinutes + 1440
        : endMinutes;
    return adjustedEnd + commuteAfterMinutes;
  }

  bool conflictsWith(RecurringCommitment other) {
    if (!active || !other.active) return false;

    const weekMinutes = 7 * 1440;
    for (final own in _weeklyIntervals()) {
      for (final candidate in other._weeklyIntervals()) {
        for (final shift in const [-weekMinutes, 0, weekMinutes]) {
          final otherStart = candidate.$1 + shift;
          final otherEnd = candidate.$2 + shift;
          if (own.$1 < otherEnd && otherStart < own.$2) return true;
        }
      }
    }
    return false;
  }

  Iterable<(int, int)> _weeklyIntervals() sync* {
    for (final day in weekdays) {
      final dayStart = (day - 1) * 1440;
      yield (dayStart + occupiedStartMinutes, dayStart + occupiedEndMinutes);
    }
  }

  static int parseTime(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String timeForDatabase(int minutes) {
    final normalized = minutes % 1440;
    final hour = (normalized ~/ 60).toString().padLeft(2, '0');
    final minute = (normalized % 60).toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }
}
