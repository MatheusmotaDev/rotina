import '../../../availability/domain/models/daily_availability.dart';
import '../../../tasks/domain/models/task_item.dart';
import '../models/daily_plan.dart';

class TaskPlanner {
  const TaskPlanner();

  List<PlannedTask> schedule({
    required List<TaskItem> tasks,
    required DailyAvailability availability,
  }) {
    final candidates =
        tasks
            .where(
              (task) =>
                  task.status != TaskStatus.completed &&
                  task.status != TaskStatus.cancelled &&
                  task.status != TaskStatus.postponed,
            )
            .toList()
          ..sort(_compare);
    final cursors = [
      for (final window in availability.freeWindows) window.start,
    ];
    final result = <PlannedTask>[];
    var allocatedMinutes = 0;

    for (final task in candidates) {
      if (allocatedMinutes + task.estimatedMinutes >
          availability.availableMinutes) {
        continue;
      }
      for (var index = 0; index < availability.freeWindows.length; index++) {
        final window = availability.freeWindows[index];
        final end = cursors[index].add(
          Duration(minutes: task.estimatedMinutes),
        );
        if (end.isAfter(window.end)) continue;
        result.add(
          PlannedTask(
            occurrenceId: task.occurrenceId,
            title: task.title,
            start: cursors[index],
            end: end,
          ),
        );
        cursors[index] = end;
        allocatedMinutes += task.estimatedMinutes;
        break;
      }
    }
    return result;
  }

  int _compare(TaskItem a, TaskItem b) {
    final priority = b.priority.index.compareTo(a.priority.index);
    if (priority != 0) return priority;
    final aDeadline = a.deadline;
    final bDeadline = b.deadline;
    if (aDeadline != null && bDeadline != null) {
      final deadline = aDeadline.compareTo(bDeadline);
      if (deadline != 0) return deadline;
    } else if (aDeadline != null) {
      return -1;
    } else if (bDeadline != null) {
      return 1;
    }
    return a.estimatedMinutes.compareTo(b.estimatedMinutes);
  }
}
