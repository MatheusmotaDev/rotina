import 'package:flutter/foundation.dart';

@immutable
class RoutineSetup {
  const RoutineSetup({
    this.isStudent = false,
    this.isWorker = false,
    this.objectives = const {'organização'},
    this.wakeMinutes = 8 * 60,
    this.sleepMinutes = 23 * 60,
    this.mealsMinutes = 90,
    this.restMinutes = 60,
    this.commuteMinutes = 60,
  });

  final bool isStudent;
  final bool isWorker;
  final Set<String> objectives;
  final int wakeMinutes;
  final int sleepMinutes;
  final int mealsMinutes;
  final int restMinutes;
  final int commuteMinutes;

  int get totalReserveMinutes => mealsMinutes + restMinutes + commuteMinutes;

  RoutineSetup copyWith({
    bool? isStudent,
    bool? isWorker,
    Set<String>? objectives,
    int? wakeMinutes,
    int? sleepMinutes,
    int? mealsMinutes,
    int? restMinutes,
    int? commuteMinutes,
  }) {
    return RoutineSetup(
      isStudent: isStudent ?? this.isStudent,
      isWorker: isWorker ?? this.isWorker,
      objectives: objectives ?? this.objectives,
      wakeMinutes: wakeMinutes ?? this.wakeMinutes,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      mealsMinutes: mealsMinutes ?? this.mealsMinutes,
      restMinutes: restMinutes ?? this.restMinutes,
      commuteMinutes: commuteMinutes ?? this.commuteMinutes,
    );
  }

  static int parseTime(String? value, {required int fallback}) {
    if (value == null) return fallback;
    final parts = value.split(':');
    if (parts.length < 2) return fallback;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return fallback;
    return hour * 60 + minute;
  }

  static String timeForDatabase(int minutes) {
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }
}
