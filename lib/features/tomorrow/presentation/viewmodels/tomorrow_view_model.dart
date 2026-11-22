import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../checkin/domain/models/daily_checkin.dart';
import '../../../commitments/data/repositories/commitments_repository.dart';
import '../../../tasks/data/repositories/tasks_repository.dart';
import '../../data/repositories/tomorrow_repository.dart';
import '../../domain/models/tomorrow_preparation.dart';

final tomorrowRepositoryProvider = Provider<TomorrowRepository>((ref) {
  final client = ref.watch(authRepositoryProvider).client;
  return TomorrowRepository(
    client,
    CommitmentsRepository(client),
    TasksRepository(client),
  );
});

class TomorrowViewModel extends AsyncNotifier<TomorrowPreparation> {
  @override
  Future<TomorrowPreparation> build() =>
      ref.watch(tomorrowRepositoryProvider).load();

  Future<void> setWakeMinutes(int minutes) async {
    final current = state.value;
    if (current == null) return;
    await _refresh(current.copyWith(wakeMinutes: minutes, saved: false));
  }

  Future<void> toggleCommitment(String id, bool confirmed) async {
    final current = state.value;
    if (current == null) return;
    final commitments = [
      for (final item in current.commitments)
        item.id == id
            ? CheckinCommitment(
                id: item.id,
                title: item.title,
                start: item.start,
                end: item.end,
                confirmed: confirmed,
              )
            : item,
    ];
    await _refresh(current.copyWith(commitments: commitments, saved: false));
  }

  void toggleTask(String id, bool selected) {
    final current = state.value;
    if (current == null) return;
    final ids = {...current.selectedTaskIds};
    selected ? ids.add(id) : ids.remove(id);
    state = AsyncData(current.copyWith(selectedTaskIds: ids, saved: false));
  }

  Future<bool> save() async {
    final current = state.value;
    if (current == null) return false;
    try {
      await ref.read(tomorrowRepositoryProvider).save(current);
      state = AsyncData(current.copyWith(saved: true));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _refresh(TomorrowPreparation value) async {
    state = AsyncData(value);
    try {
      state = AsyncData(
        await ref.read(tomorrowRepositoryProvider).refreshPreview(value),
      );
    } catch (_) {
      state = AsyncData(value);
    }
  }
}

final tomorrowViewModelProvider =
    AsyncNotifierProvider<TomorrowViewModel, TomorrowPreparation>(
      TomorrowViewModel.new,
    );
