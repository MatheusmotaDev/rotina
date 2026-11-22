import 'package:flutter_test/flutter_test.dart';
import 'package:rotina/features/availability/domain/models/daily_availability.dart';
import 'package:rotina/features/planning/domain/services/task_planner.dart';
import 'package:rotina/features/tasks/domain/models/task_item.dart';

void main() {
  const planner = TaskPlanner();

  test('prioriza tarefa urgente e respeita janelas contínuas', () {
    final availability = buildAvailability(
      windows: [
        TimeInterval(
          start: DateTime(2026, 11, 23, 9),
          end: DateTime(2026, 11, 23, 10),
        ),
        TimeInterval(
          start: DateTime(2026, 11, 23, 14),
          end: DateTime(2026, 11, 23, 16),
        ),
      ],
      availableMinutes: 180,
    );
    final result = planner.schedule(
      tasks: [
        buildTask('baixa', 60, TaskPriority.low),
        buildTask('urgente', 90, TaskPriority.high),
      ],
      availability: availability,
    );

    expect(result.first.title, 'urgente');
    expect(result.first.start, DateTime(2026, 11, 23, 14));
    expect(result[1].start, DateTime(2026, 11, 23, 9));
  });

  test('não agenda tarefa que não cabe em bloco contínuo', () {
    final availability = buildAvailability(
      windows: [
        TimeInterval(
          start: DateTime(2026, 11, 23, 9),
          end: DateTime(2026, 11, 23, 9, 30),
        ),
        TimeInterval(
          start: DateTime(2026, 11, 23, 10),
          end: DateTime(2026, 11, 23, 10, 30),
        ),
      ],
      availableMinutes: 60,
    );

    expect(
      planner.schedule(
        tasks: [buildTask('longa', 60, TaskPriority.high)],
        availability: availability,
      ),
      isEmpty,
    );
  });
}

DailyAvailability buildAvailability({
  required List<TimeInterval> windows,
  required int availableMinutes,
}) => DailyAvailability(
  awakeStart: DateTime(2026, 11, 23, 8),
  awakeEnd: DateTime(2026, 11, 23, 23),
  awakeMinutes: 900,
  busyMinutes: 0,
  personalReserveMinutes: 0,
  availableMinutes: availableMinutes,
  freePercentage: availableMinutes / 900,
  freeWindows: windows,
  hasConflicts: false,
  overloaded: false,
  provisional: false,
);

TaskItem buildTask(String title, int minutes, TaskPriority priority) {
  final date = DateTime(2026, 11, 23);
  return TaskItem(
    id: title,
    title: title,
    priority: priority,
    estimatedMinutes: minutes,
    initialDate: date,
    repeat: TaskRepeat.none,
    weekdays: const {},
    occurrenceId: 'occ-$title',
    occurrenceDate: date,
    status: TaskStatus.pending,
  );
}
