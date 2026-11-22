import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../availability/presentation/viewmodels/availability_provider.dart';
import '../../../breaks/presentation/viewmodels/breaks_view_model.dart';
import '../../../checkin/presentation/viewmodels/checkin_view_model.dart';
import '../../../commitments/presentation/viewmodels/commitments_view_model.dart';
import '../../../tasks/domain/models/task_item.dart';
import '../../../tasks/presentation/viewmodels/tasks_view_model.dart';
import '../../data/repositories/planning_repository.dart';
import '../../domain/models/daily_plan.dart';
import '../../domain/services/task_planner.dart';

final planningRepositoryProvider = Provider<PlanningRepository>((ref) {
  return PlanningRepository(ref.watch(authRepositoryProvider).client);
});

class PlanningViewModel extends AsyncNotifier<DailyPlan> {
  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Future<DailyPlan> build() async {
    final date = _today;
    final availability = await ref.watch(availabilityProvider.future);
    final tasks = await ref.watch(tasksViewModelProvider(date).future);
    final commitments = await ref.watch(dailyCommitmentsProvider(date).future);
    final checkin = await ref.watch(checkinViewModelProvider.future);
    final breaks = await ref.watch(breaksViewModelProvider.future);
    final stored = await ref.watch(planningRepositoryProvider).load(date);
    final draft = const TaskPlanner().schedule(
      tasks: tasks,
      availability: availability,
    );
    final timeline = <TimelineEntry>[
      for (final commitment in commitments)
        TimelineEntry(
          title: commitment.source.title,
          start: commitment.start,
          end: commitment.end,
          type: TimelineEntryType.commitment,
        ),
      for (final task in stored.tasks)
        TimelineEntry(
          title: task.title,
          start: task.start,
          end: task.end,
          type: TimelineEntryType.task,
        ),
      for (final pause in breaks.where(
        (pause) => _sameDay(pause.startedAt, date),
      ))
        TimelineEntry(
          title: pause.active ? 'Pausa em andamento' : 'Pausa registrada',
          start: pause.startedAt,
          end: pause.endedAt ?? DateTime.now(),
          type: TimelineEntryType.breakTime,
        ),
    ]..sort((a, b) => a.start.compareTo(b.start));
    return DailyPlan(
      id: stored.id,
      date: date,
      state: stored.state,
      version: stored.version,
      timeline: timeline,
      currentTasks: stored.tasks,
      draftTasks: draft,
      proposal: stored.proposal,
      hasReplanningReason:
          checkin.wakeDifferenceMinutes > 15 ||
          checkin.commitments.any((item) => !item.confirmed) ||
          availability.hasConflicts ||
          availability.overloaded ||
          tasks.any(
            (task) => task.status == TaskStatus.postponed || task.isOverdue,
          ),
    );
  }

  Future<bool> confirmInitial() async {
    final plan = state.value;
    if (plan == null) return false;
    return _run(
      () => ref
          .read(planningRepositoryProvider)
          .confirmInitial(plan.date, plan.draftTasks),
    );
  }

  Future<bool> generateProposal() async {
    final plan = state.value;
    if (plan?.id == null) return false;
    return _run(
      () => ref
          .read(planningRepositoryProvider)
          .createProposal(
            planningId: plan!.id!,
            baseVersion: plan.version,
            date: plan.date,
            reason: plan.hasReplanningReason ? 'mudanca' : 'manual',
            current: plan.currentTasks,
            suggested: plan.draftTasks,
          ),
    );
  }

  Future<bool> rejectProposal() async {
    final proposal = state.value?.proposal;
    if (proposal == null) return false;
    return _run(() => ref.read(planningRepositoryProvider).reject(proposal.id));
  }

  Future<bool> adjust(PlannedTask task, DateTime start) async {
    final plan = state.value;
    if (plan?.proposal == null || task.changeId == null) return false;
    final end = start.add(Duration(minutes: task.durationMinutes));
    final availability = await ref.refresh(availabilityProvider.future);
    final insideWindow = availability.freeWindows.any(
      (window) => !start.isBefore(window.start) && !end.isAfter(window.end),
    );
    final conflicts = plan!.proposal!.suggested.any(
      (other) =>
          other.changeId != task.changeId &&
          start.isBefore(other.end) &&
          other.start.isBefore(end),
    );
    if (!insideWindow || conflicts) return false;
    return _run(() => ref.read(planningRepositoryProvider).adjust(task, start));
  }

  Future<bool> approveProposal() async {
    final proposal = state.value?.proposal;
    if (proposal == null) return false;
    final availability = await ref.refresh(availabilityProvider.future);
    for (final task in proposal.suggested) {
      final valid = availability.freeWindows.any(
        (window) =>
            !task.start.isBefore(window.start) && !task.end.isAfter(window.end),
      );
      if (!valid) return false;
    }
    for (var index = 0; index < proposal.suggested.length; index++) {
      for (var other = index + 1; other < proposal.suggested.length; other++) {
        final first = proposal.suggested[index];
        final second = proposal.suggested[other];
        if (first.start.isBefore(second.end) &&
            second.start.isBefore(first.end)) {
          return false;
        }
      }
    }
    return _run(
      () => ref.read(planningRepositoryProvider).approve(proposal.id),
    );
  }

  Future<bool> _run(Future<void> Function() operation) async {
    try {
      await operation();
      ref.invalidateSelf();
      await future;
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

final planningViewModelProvider =
    AsyncNotifierProvider<PlanningViewModel, DailyPlan>(PlanningViewModel.new);
