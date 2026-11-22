import '../models/daily_availability.dart';

class AvailabilityEngine {
  const AvailabilityEngine();

  DailyAvailability calculate(AvailabilityInput input) {
    if (!input.awakeEnd.isAfter(input.awakeStart)) {
      throw ArgumentError(
        'O fim do período acordado deve ser posterior ao início.',
      );
    }

    final clipped =
        input.busyIntervals
            .map(
              (interval) => _clip(interval, input.awakeStart, input.awakeEnd),
            )
            .whereType<TimeInterval>()
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    final hasConflicts = _hasOverlap(clipped);
    final merged = _merge(clipped);
    final windows = _freeWindows(input.awakeStart, input.awakeEnd, merged);
    final awakeMinutes = input.awakeEnd.difference(input.awakeStart).inMinutes;
    final busyMinutes = merged.fold<int>(
      0,
      (total, interval) => total + interval.durationMinutes,
    );
    final rawFreeMinutes = (awakeMinutes - busyMinutes).clamp(0, awakeMinutes);
    final availableMinutes = (rawFreeMinutes - input.personalReserveMinutes)
        .clamp(0, awakeMinutes);

    return DailyAvailability(
      awakeStart: input.awakeStart,
      awakeEnd: input.awakeEnd,
      awakeMinutes: awakeMinutes,
      busyMinutes: busyMinutes,
      personalReserveMinutes: input.personalReserveMinutes,
      availableMinutes: availableMinutes,
      freePercentage: awakeMinutes == 0 ? 0 : availableMinutes / awakeMinutes,
      freeWindows: windows,
      hasConflicts: hasConflicts,
      overloaded: busyMinutes + input.personalReserveMinutes > awakeMinutes,
      provisional: input.provisional,
    );
  }

  TimeInterval? _clip(TimeInterval interval, DateTime start, DateTime end) {
    final clippedStart = interval.start.isBefore(start)
        ? start
        : interval.start;
    final clippedEnd = interval.end.isAfter(end) ? end : interval.end;
    if (!clippedEnd.isAfter(clippedStart)) return null;
    return TimeInterval(
      start: clippedStart,
      end: clippedEnd,
      label: interval.label,
    );
  }

  bool _hasOverlap(List<TimeInterval> intervals) {
    if (intervals.isEmpty) return false;
    var furthestEnd = intervals.first.end;
    for (var index = 1; index < intervals.length; index++) {
      if (intervals[index].start.isBefore(furthestEnd)) return true;
      if (intervals[index].end.isAfter(furthestEnd)) {
        furthestEnd = intervals[index].end;
      }
    }
    return false;
  }

  List<TimeInterval> _merge(List<TimeInterval> intervals) {
    final merged = <TimeInterval>[];
    for (final current in intervals) {
      if (merged.isEmpty || current.start.isAfter(merged.last.end)) {
        merged.add(current);
        continue;
      }
      final previous = merged.removeLast();
      merged.add(
        TimeInterval(
          start: previous.start,
          end: current.end.isAfter(previous.end) ? current.end : previous.end,
        ),
      );
    }
    return merged;
  }

  List<TimeInterval> _freeWindows(
    DateTime start,
    DateTime end,
    List<TimeInterval> busy,
  ) {
    final windows = <TimeInterval>[];
    var cursor = start;
    for (final interval in busy) {
      if (interval.start.isAfter(cursor)) {
        windows.add(TimeInterval(start: cursor, end: interval.start));
      }
      if (interval.end.isAfter(cursor)) cursor = interval.end;
    }
    if (cursor.isBefore(end)) {
      windows.add(TimeInterval(start: cursor, end: end));
    }
    return windows;
  }
}
