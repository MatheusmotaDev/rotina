import '../models/task_item.dart';

class TaskSchedule {
  const TaskSchedule();

  bool applies({
    required TaskRepeat repeat,
    required DateTime initialDate,
    required DateTime? finalDate,
    required Set<int> weekdays,
    required DateTime date,
  }) {
    final target = _dateOnly(date);
    final initial = _dateOnly(initialDate);
    final end = finalDate == null ? null : _dateOnly(finalDate);

    if (target.isBefore(initial) || (end != null && target.isAfter(end))) {
      return false;
    }

    return switch (repeat) {
      TaskRepeat.daily => true,
      TaskRepeat.weekly => weekdays.contains(target.weekday),
      TaskRepeat.none => target == initial,
    };
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
