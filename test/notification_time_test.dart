import 'package:flutter_test/flutter_test.dart';
import 'package:rotina/features/notifications/domain/services/notification_time.dart';

void main() {
  const time = NotificationTime();

  test('agenda lembrete no mesmo dia quando o horário ainda não passou', () {
    expect(
      time.nextDaily(DateTime(2026, 11, 22, 7), 8 * 60),
      DateTime(2026, 11, 22, 8),
    );
  });

  test('agenda lembrete no dia seguinte quando o horário passou', () {
    expect(
      time.nextDaily(DateTime(2026, 11, 22, 9), 8 * 60),
      DateTime(2026, 11, 23, 8),
    );
  });
}
