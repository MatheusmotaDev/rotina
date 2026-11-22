import 'package:flutter/foundation.dart';

enum FocusMode { pomodoro, free }

enum FocusSessionState { running, paused, completed, cancelled }

@immutable
class FocusSession {
  const FocusSession({
    required this.id,
    required this.mode,
    required this.state,
    required this.startedAt,
    required this.pausedSeconds,
    this.plannedMinutes,
    this.taskOccurrenceId,
    this.endedAt,
    this.pausedAt,
  });

  final String id;
  final String? taskOccurrenceId;
  final FocusMode mode;
  final FocusSessionState state;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime? pausedAt;
  final int pausedSeconds;
  final int? plannedMinutes;

  Duration elapsed([DateTime? now]) {
    final reference = endedAt ?? pausedAt ?? now ?? DateTime.now();
    final seconds = reference.difference(startedAt).inSeconds - pausedSeconds;
    return Duration(seconds: seconds < 0 ? 0 : seconds);
  }
}
