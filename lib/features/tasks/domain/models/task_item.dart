import 'package:flutter/foundation.dart';

enum TaskPriority { low, medium, high }

enum TaskRepeat { none, daily, weekly }

enum TaskStatus { pending, inProgress, completed, postponed, cancelled }

@immutable
class TaskCategory {
  const TaskCategory({required this.id, required this.name, this.color});

  final String id;
  final String name;
  final String? color;
}

@immutable
class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.estimatedMinutes,
    required this.initialDate,
    required this.repeat,
    required this.weekdays,
    required this.occurrenceId,
    required this.occurrenceDate,
    required this.status,
    this.description,
    this.category,
    this.deadline,
    this.finalDate,
  });

  final String id;
  final String title;
  final String? description;
  final TaskCategory? category;
  final TaskPriority priority;
  final int estimatedMinutes;
  final DateTime? deadline;
  final DateTime initialDate;
  final DateTime? finalDate;
  final TaskRepeat repeat;
  final Set<int> weekdays;
  final String occurrenceId;
  final DateTime occurrenceDate;
  final TaskStatus status;

  bool get isOverdue =>
      deadline != null &&
      deadline!.isBefore(DateTime.now()) &&
      status != TaskStatus.completed &&
      status != TaskStatus.cancelled;
}
