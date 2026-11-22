import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../commitments/presentation/viewmodels/commitments_view_model.dart';
import '../../data/repositories/checkin_repository.dart';
import '../../domain/models/daily_checkin.dart';

final checkinRepositoryProvider = Provider<CheckinRepository>((ref) {
  return CheckinRepository(
    ref.watch(authRepositoryProvider).client,
    ref.watch(commitmentsRepositoryProvider),
  );
});

class CheckinViewModel extends AsyncNotifier<DailyCheckin> {
  @override
  Future<DailyCheckin> build() {
    return ref.watch(checkinRepositoryProvider).loadToday();
  }

  void setWakeTime(DateTime value) =>
      _update((checkin) => checkin.copyWith(actualWake: value));

  void setEnergy(EnergyLevel value) =>
      _update((checkin) => checkin.copyWith(energy: value));

  void setCommitment(String id, bool confirmed) {
    _update(
      (checkin) => checkin.copyWith(
        commitments: checkin.commitments
            .map(
              (item) =>
                  item.id == id ? item.copyWith(confirmed: confirmed) : item,
            )
            .toList(),
      ),
    );
  }

  void setObservation(String value) =>
      _update((checkin) => checkin.copyWith(observation: value));

  Future<bool> save() async {
    final checkin = state.value;
    if (checkin == null) return false;
    try {
      await ref.read(checkinRepositoryProvider).save(checkin);
      state = AsyncData(checkin.copyWith(completed: true));
      return true;
    } catch (_) {
      return false;
    }
  }

  void _update(DailyCheckin Function(DailyCheckin value) transform) {
    final value = state.value;
    if (value != null) state = AsyncData(transform(value));
  }
}

final checkinViewModelProvider =
    AsyncNotifierProvider<CheckinViewModel, DailyCheckin>(CheckinViewModel.new);
