import 'package:flutter/foundation.dart';

@immutable
class HomeSummary {
  const HomeSummary({
    required this.userName,
    required this.freeMinutes,
    required this.completedTasks,
    required this.totalTasks,
    required this.nextActivityTitle,
    required this.nextActivityTime,
    required this.checkInCompleted,
  });

  final String userName;
  final int freeMinutes;
  final int completedTasks;
  final int totalTasks;
  final String nextActivityTitle;
  final String nextActivityTime;
  final bool checkInCompleted;

  double get progress => totalTasks == 0 ? 0 : completedTasks / totalTasks;

  String get formattedFreeTime {
    final hours = freeMinutes ~/ 60;
    final minutes = freeMinutes % 60;
    return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}min';
  }
}
