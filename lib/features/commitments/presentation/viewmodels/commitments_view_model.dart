import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../data/repositories/commitments_repository.dart';
import '../../domain/models/daily_commitment.dart';
import '../../domain/models/recurring_commitment.dart';

final commitmentsRepositoryProvider = Provider<CommitmentsRepository>((ref) {
  return CommitmentsRepository(ref.watch(authRepositoryProvider).client);
});

class CommitmentsViewModel extends AsyncNotifier<List<RecurringCommitment>> {
  @override
  Future<List<RecurringCommitment>> build() {
    return ref.watch(commitmentsRepositoryProvider).load();
  }

  Future<bool> create({
    required String title,
    required CommitmentType type,
    required Set<int> weekdays,
    required int startMinutes,
    required int endMinutes,
    required int commuteBeforeMinutes,
    required int commuteAfterMinutes,
  }) {
    return _run(
      () => ref
          .read(commitmentsRepositoryProvider)
          .create(
            title: title,
            type: type,
            weekdays: weekdays,
            startMinutes: startMinutes,
            endMinutes: endMinutes,
            commuteBeforeMinutes: commuteBeforeMinutes,
            commuteAfterMinutes: commuteAfterMinutes,
          ),
    );
  }

  Future<bool> edit(
    RecurringCommitment commitment, {
    required String title,
    required CommitmentType type,
    required Set<int> weekdays,
    required int startMinutes,
    required int endMinutes,
    required int commuteBeforeMinutes,
    required int commuteAfterMinutes,
  }) {
    return _run(
      () => ref
          .read(commitmentsRepositoryProvider)
          .update(
            commitment,
            title: title,
            type: type,
            weekdays: weekdays,
            startMinutes: startMinutes,
            endMinutes: endMinutes,
            commuteBeforeMinutes: commuteBeforeMinutes,
            commuteAfterMinutes: commuteAfterMinutes,
          ),
    );
  }

  Future<bool> setActive(RecurringCommitment commitment, bool active) {
    return _run(
      () =>
          ref.read(commitmentsRepositoryProvider).setActive(commitment, active),
    );
  }

  Future<bool> delete(RecurringCommitment commitment) {
    return _run(
      () => ref.read(commitmentsRepositoryProvider).delete(commitment),
    );
  }

  Future<bool> _run(Future<void> Function() operation) async {
    try {
      await operation();
      state = AsyncData(await ref.read(commitmentsRepositoryProvider).load());
      return true;
    } catch (_) {
      return false;
    }
  }
}

final commitmentsViewModelProvider =
    AsyncNotifierProvider<CommitmentsViewModel, List<RecurringCommitment>>(
      CommitmentsViewModel.new,
    );

final dailyCommitmentsProvider =
    FutureProvider.family<List<DailyCommitment>, DateTime>(
      (ref, date) => ref.watch(commitmentsRepositoryProvider).loadForDate(date),
    );
