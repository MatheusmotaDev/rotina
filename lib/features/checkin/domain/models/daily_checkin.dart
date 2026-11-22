import 'package:flutter/foundation.dart';

enum EnergyLevel { low, normal, high }

@immutable
class CheckinCommitment {
  const CheckinCommitment({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.confirmed,
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final bool confirmed;

  CheckinCommitment copyWith({bool? confirmed}) {
    return CheckinCommitment(
      id: id,
      title: title,
      start: start,
      end: end,
      confirmed: confirmed ?? this.confirmed,
    );
  }
}

@immutable
class DailyCheckin {
  const DailyCheckin({
    required this.date,
    required this.plannedWakeMinutes,
    required this.actualWake,
    required this.energy,
    required this.commitments,
    required this.completed,
    this.observation = '',
  });

  final DateTime date;
  final int plannedWakeMinutes;
  final DateTime actualWake;
  final EnergyLevel energy;
  final List<CheckinCommitment> commitments;
  final bool completed;
  final String observation;

  int get wakeDifferenceMinutes {
    final planned = DateTime(
      date.year,
      date.month,
      date.day,
      plannedWakeMinutes ~/ 60,
      plannedWakeMinutes % 60,
    );
    return actualWake.difference(planned).inMinutes;
  }

  DailyCheckin copyWith({
    DateTime? actualWake,
    EnergyLevel? energy,
    List<CheckinCommitment>? commitments,
    bool? completed,
    String? observation,
  }) {
    return DailyCheckin(
      date: date,
      plannedWakeMinutes: plannedWakeMinutes,
      actualWake: actualWake ?? this.actualWake,
      energy: energy ?? this.energy,
      commitments: commitments ?? this.commitments,
      completed: completed ?? this.completed,
      observation: observation ?? this.observation,
    );
  }
}
