import 'package:flutter/foundation.dart';

import '../../../availability/domain/models/daily_availability.dart';
import '../../../checkin/domain/models/daily_checkin.dart';
import '../../../tasks/domain/models/task_item.dart';

@immutable
class TomorrowPreparation {
  const TomorrowPreparation({
    required this.date,
    required this.wakeMinutes,
    required this.commitments,
    required this.pendingTasks,
    required this.selectedTaskIds,
    required this.preview,
    required this.saved,
  });

  final DateTime date;
  final int wakeMinutes;
  final List<CheckinCommitment> commitments;
  final List<TaskItem> pendingTasks;
  final Set<String> selectedTaskIds;
  final DailyAvailability preview;
  final bool saved;

  TomorrowPreparation copyWith({
    int? wakeMinutes,
    List<CheckinCommitment>? commitments,
    Set<String>? selectedTaskIds,
    DailyAvailability? preview,
    bool? saved,
  }) => TomorrowPreparation(
    date: date,
    wakeMinutes: wakeMinutes ?? this.wakeMinutes,
    commitments: commitments ?? this.commitments,
    pendingTasks: pendingTasks,
    selectedTaskIds: selectedTaskIds ?? this.selectedTaskIds,
    preview: preview ?? this.preview,
    saved: saved ?? this.saved,
  );
}
