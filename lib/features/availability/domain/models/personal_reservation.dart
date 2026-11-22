import 'package:flutter/foundation.dart';

@immutable
class PersonalReservation {
  const PersonalReservation({
    required this.id,
    required this.title,
    required this.weekdays,
    required this.startMinutes,
    required this.endMinutes,
    required this.active,
  });

  final String id;
  final String title;
  final Set<int> weekdays;
  final int startMinutes;
  final int endMinutes;
  final bool active;

  bool appliesTo(DateTime date) => active && weekdays.contains(date.weekday);

  DateTime startAt(DateTime date) => DateTime(
    date.year,
    date.month,
    date.day,
    startMinutes ~/ 60,
    startMinutes % 60,
  );

  DateTime endAt(DateTime date) {
    final start = startAt(date);
    var end = DateTime(
      date.year,
      date.month,
      date.day,
      endMinutes ~/ 60,
      endMinutes % 60,
    );
    if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
    return end;
  }
}
