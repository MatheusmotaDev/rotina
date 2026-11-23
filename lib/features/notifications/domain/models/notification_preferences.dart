import 'package:flutter/foundation.dart';

@immutable
class NotificationPreferences {
  const NotificationPreferences({
    required this.checkin,
    required this.taskStarts,
    required this.commitments,
    required this.breakEnd,
    required this.nightlySummary,
    required this.checkinMinutes,
    required this.nightlyMinutes,
    required this.leadMinutes,
  });

  const NotificationPreferences.defaults()
    : checkin = true,
      taskStarts = true,
      commitments = true,
      breakEnd = true,
      nightlySummary = true,
      checkinMinutes = 8 * 60,
      nightlyMinutes = 21 * 60,
      leadMinutes = 10;

  final bool checkin;
  final bool taskStarts;
  final bool commitments;
  final bool breakEnd;
  final bool nightlySummary;
  final int checkinMinutes;
  final int nightlyMinutes;
  final int leadMinutes;

  NotificationPreferences copyWith({
    bool? checkin,
    bool? taskStarts,
    bool? commitments,
    bool? breakEnd,
    bool? nightlySummary,
    int? checkinMinutes,
    int? nightlyMinutes,
    int? leadMinutes,
  }) => NotificationPreferences(
    checkin: checkin ?? this.checkin,
    taskStarts: taskStarts ?? this.taskStarts,
    commitments: commitments ?? this.commitments,
    breakEnd: breakEnd ?? this.breakEnd,
    nightlySummary: nightlySummary ?? this.nightlySummary,
    checkinMinutes: checkinMinutes ?? this.checkinMinutes,
    nightlyMinutes: nightlyMinutes ?? this.nightlyMinutes,
    leadMinutes: leadMinutes ?? this.leadMinutes,
  );
}
