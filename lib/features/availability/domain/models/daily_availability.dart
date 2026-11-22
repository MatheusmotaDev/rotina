import 'package:flutter/foundation.dart';

@immutable
class TimeInterval {
  const TimeInterval({required this.start, required this.end, this.label});

  final DateTime start;
  final DateTime end;
  final String? label;

  int get durationMinutes => end.difference(start).inMinutes;
}

@immutable
class AvailabilityInput {
  const AvailabilityInput({
    required this.awakeStart,
    required this.awakeEnd,
    required this.busyIntervals,
    required this.personalReserveMinutes,
    required this.provisional,
  });

  final DateTime awakeStart;
  final DateTime awakeEnd;
  final List<TimeInterval> busyIntervals;
  final int personalReserveMinutes;
  final bool provisional;
}

@immutable
class DailyAvailability {
  const DailyAvailability({
    required this.awakeStart,
    required this.awakeEnd,
    required this.awakeMinutes,
    required this.busyMinutes,
    required this.personalReserveMinutes,
    required this.availableMinutes,
    required this.freePercentage,
    required this.freeWindows,
    required this.hasConflicts,
    required this.overloaded,
    required this.provisional,
  });

  final DateTime awakeStart;
  final DateTime awakeEnd;
  final int awakeMinutes;
  final int busyMinutes;
  final int personalReserveMinutes;
  final int availableMinutes;
  final double freePercentage;
  final List<TimeInterval> freeWindows;
  final bool hasConflicts;
  final bool overloaded;
  final bool provisional;

  bool canFit(int durationMinutes) {
    if (durationMinutes <= 0 || durationMinutes > availableMinutes) {
      return false;
    }
    return freeWindows.any(
      (window) => window.durationMinutes >= durationMinutes,
    );
  }
}
