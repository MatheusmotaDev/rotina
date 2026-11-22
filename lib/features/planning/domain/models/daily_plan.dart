import 'package:flutter/foundation.dart';

enum PlanState { provisional, confirmed, closed }

enum ProposalState { pending, approved, rejected }

enum TimelineEntryType { commitment, task, breakTime, personal }

@immutable
class PlannedTask {
  const PlannedTask({
    required this.occurrenceId,
    required this.title,
    required this.start,
    required this.end,
    this.blockId,
    this.changeId,
  });

  final String? blockId;
  final String? changeId;
  final String occurrenceId;
  final String title;
  final DateTime start;
  final DateTime end;

  int get durationMinutes => end.difference(start).inMinutes;

  PlannedTask copyWith({DateTime? start, DateTime? end}) => PlannedTask(
    blockId: blockId,
    changeId: changeId,
    occurrenceId: occurrenceId,
    title: title,
    start: start ?? this.start,
    end: end ?? this.end,
  );
}

@immutable
class TimelineEntry {
  const TimelineEntry({
    required this.title,
    required this.start,
    required this.end,
    required this.type,
  });

  final String title;
  final DateTime start;
  final DateTime end;
  final TimelineEntryType type;
}

@immutable
class ReplanningProposal {
  const ReplanningProposal({
    required this.id,
    required this.planningId,
    required this.baseVersion,
    required this.state,
    required this.current,
    required this.suggested,
    required this.reason,
  });

  final String id;
  final String planningId;
  final int baseVersion;
  final ProposalState state;
  final List<PlannedTask> current;
  final List<PlannedTask> suggested;
  final String reason;
}

@immutable
class DailyPlan {
  const DailyPlan({
    required this.date,
    required this.state,
    required this.version,
    required this.timeline,
    required this.currentTasks,
    required this.draftTasks,
    required this.hasReplanningReason,
    this.id,
    this.proposal,
  });

  final String? id;
  final DateTime date;
  final PlanState state;
  final int version;
  final List<TimelineEntry> timeline;
  final List<PlannedTask> currentTasks;
  final List<PlannedTask> draftTasks;
  final bool hasReplanningReason;
  final ReplanningProposal? proposal;
}
