import 'package:flutter/foundation.dart';

@immutable
class BreakSession {
  const BreakSession({
    required this.id,
    required this.startedAt,
    required this.reminderEnabled,
    this.endedAt,
    this.plannedMinutes,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? plannedMinutes;
  final bool reminderEnabled;

  bool get active => endedAt == null;

  Duration elapsed([DateTime? now]) =>
      (endedAt ?? now ?? DateTime.now()).difference(startedAt);

  DateTime? get plannedEnd => plannedMinutes == null
      ? null
      : startedAt.add(Duration(minutes: plannedMinutes!));

  bool reminderDue([DateTime? now]) =>
      active &&
      reminderEnabled &&
      plannedEnd != null &&
      !(now ?? DateTime.now()).isBefore(plannedEnd!);
}
