import 'package:flutter_test/flutter_test.dart';
import 'package:rotina/features/focus/domain/models/focus_session.dart';

void main() {
  test('calcula duração efetiva sem contar pausas encerradas', () {
    final session = FocusSession(
      id: '1',
      mode: FocusMode.free,
      state: FocusSessionState.completed,
      startedAt: DateTime(2026, 11, 22, 10),
      endedAt: DateTime(2026, 11, 22, 11),
      pausedSeconds: 600,
    );

    expect(session.elapsed(), const Duration(minutes: 50));
  });

  test('sessão pausada congela a duração no instante da pausa', () {
    final session = FocusSession(
      id: '1',
      mode: FocusMode.pomodoro,
      state: FocusSessionState.paused,
      startedAt: DateTime(2026, 11, 22, 10),
      pausedAt: DateTime(2026, 11, 22, 10, 25),
      pausedSeconds: 300,
    );

    expect(
      session.elapsed(DateTime(2026, 11, 22, 12)),
      const Duration(minutes: 20),
    );
  });
}
