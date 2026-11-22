import 'package:flutter_test/flutter_test.dart';
import 'package:rotina/features/tasks/domain/models/task_item.dart';
import 'package:rotina/features/tasks/domain/services/task_schedule.dart';

void main() {
  const schedule = TaskSchedule();

  test('tarefa pontual ocorre apenas na data inicial', () {
    final initial = DateTime(2026, 11, 22);

    expect(
      schedule.applies(
        repeat: TaskRepeat.none,
        initialDate: initial,
        finalDate: null,
        weekdays: const {},
        date: initial,
      ),
      isTrue,
    );
    expect(
      schedule.applies(
        repeat: TaskRepeat.none,
        initialDate: initial,
        finalDate: null,
        weekdays: const {},
        date: DateTime(2026, 11, 23),
      ),
      isFalse,
    );
  });

  test('tarefa semanal respeita os dias selecionados', () {
    expect(
      schedule.applies(
        repeat: TaskRepeat.weekly,
        initialDate: DateTime(2026, 11, 1),
        finalDate: null,
        weekdays: const {DateTime.monday, DateTime.wednesday},
        date: DateTime(2026, 11, 23),
      ),
      isTrue,
    );
    expect(
      schedule.applies(
        repeat: TaskRepeat.weekly,
        initialDate: DateTime(2026, 11, 1),
        finalDate: null,
        weekdays: const {DateTime.monday, DateTime.wednesday},
        date: DateTime(2026, 11, 24),
      ),
      isFalse,
    );
  });

  test('tarefa diária respeita o término da recorrência', () {
    expect(
      schedule.applies(
        repeat: TaskRepeat.daily,
        initialDate: DateTime(2026, 11, 20),
        finalDate: DateTime(2026, 11, 22),
        weekdays: const {},
        date: DateTime(2026, 11, 22, 23),
      ),
      isTrue,
    );
    expect(
      schedule.applies(
        repeat: TaskRepeat.daily,
        initialDate: DateTime(2026, 11, 20),
        finalDate: DateTime(2026, 11, 22),
        weekdays: const {},
        date: DateTime(2026, 11, 23),
      ),
      isFalse,
    );
  });
}
