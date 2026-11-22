import 'package:flutter_test/flutter_test.dart';
import 'package:rotina/features/availability/domain/models/daily_availability.dart';
import 'package:rotina/features/availability/domain/services/availability_engine.dart';

void main() {
  final date = DateTime(2026, 11, 22);
  DateTime at(int hour, [int minute = 0]) =>
      DateTime(date.year, date.month, date.day, hour, minute);

  DailyAvailability calculate({
    required List<TimeInterval> busy,
    int reserve = 0,
  }) {
    return const AvailabilityEngine().calculate(
      AvailabilityInput(
        awakeStart: DateTime(2026, 11, 22, 8),
        awakeEnd: DateTime(2026, 11, 22, 20),
        busyIntervals: busy,
        personalReserveMinutes: reserve,
        provisional: false,
      ),
    );
  }

  test('não desconta duas vezes intervalos sobrepostos', () {
    final result = calculate(
      busy: [
        TimeInterval(start: at(9), end: at(11)),
        TimeInterval(start: at(10), end: at(12)),
      ],
    );

    expect(result.busyMinutes, 180);
    expect(result.availableMinutes, 540);
    expect(result.hasConflicts, isTrue);
  });

  test('recorta compromissos para o período acordado', () {
    final result = calculate(
      busy: [TimeInterval(start: at(7), end: at(9))],
    );

    expect(result.busyMinutes, 60);
    expect(result.freeWindows.first.start, at(9));
  });

  test('desconta a reserva pessoal do total disponível', () {
    final result = calculate(busy: const [], reserve: 120);

    expect(result.awakeMinutes, 720);
    expect(result.availableMinutes, 600);
    expect(result.freePercentage, closeTo(5 / 6, 0.001));
  });

  test('tarefa precisa caber em uma janela contínua', () {
    final result = const AvailabilityEngine().calculate(
      AvailabilityInput(
        awakeStart: DateTime(2026, 11, 22, 8),
        awakeEnd: DateTime(2026, 11, 22, 10),
        busyIntervals: [
          TimeInterval(
            start: DateTime(2026, 11, 22, 8, 30),
            end: DateTime(2026, 11, 22, 9, 30),
          ),
        ],
        personalReserveMinutes: 0,
        provisional: false,
      ),
    );

    expect(result.availableMinutes, 60);
    expect(result.canFit(30), isTrue);
    expect(result.canFit(60), isFalse);
  });

  test('identifica sobrecarga quando reservas excedem o período', () {
    final result = calculate(busy: const [], reserve: 800);

    expect(result.availableMinutes, 0);
    expect(result.overloaded, isTrue);
  });

  test('detecta sobreposição mesmo com intervalo contido entre outros', () {
    final result = calculate(
      busy: [
        TimeInterval(start: at(9), end: at(15)),
        TimeInterval(start: at(10), end: at(11)),
        TimeInterval(start: at(14), end: at(16)),
      ],
    );

    expect(result.hasConflicts, isTrue);
    expect(result.busyMinutes, 420);
  });
}
