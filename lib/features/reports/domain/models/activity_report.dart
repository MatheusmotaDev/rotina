import 'package:flutter/foundation.dart';

@immutable
class DailyActivityReport {
  const DailyActivityReport({
    required this.date,
    required this.completedTasks,
    required this.pendingTasks,
    required this.postponedTasks,
    required this.estimatedMinutes,
    required this.focusMinutes,
    required this.restMinutes,
    required this.plannedWakeMinutes,
    required this.actualWake,
    required this.feedback,
  });

  final DateTime date;
  final int completedTasks;
  final int pendingTasks;
  final int postponedTasks;
  final int estimatedMinutes;
  final int focusMinutes;
  final int restMinutes;
  final int? plannedWakeMinutes;
  final DateTime? actualWake;
  final String feedback;

  int get totalTasks => completedTasks + pendingTasks + postponedTasks;

  double? get completionRate =>
      totalTasks == 0 ? null : completedTasks / totalTasks;
}

@immutable
class WeeklyActivityReport {
  const WeeklyActivityReport({required this.days});

  final List<DailyActivityReport> days;

  int get completedTasks =>
      days.fold(0, (total, day) => total + day.completedTasks);
  int get totalTasks => days.fold(0, (total, day) => total + day.totalTasks);
  int get focusMinutes =>
      days.fold(0, (total, day) => total + day.focusMinutes);
  int get restMinutes => days.fold(0, (total, day) => total + day.restMinutes);
  int get checkinDays => days.where((day) => day.actualWake != null).length;
  double? get completionRate =>
      totalTasks == 0 ? null : completedTasks / totalTasks;
}
