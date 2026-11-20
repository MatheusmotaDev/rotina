import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../domain/models/routine_setup.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final client = ref.watch(authRepositoryProvider).client;
  return OnboardingRepository(client);
});

class OnboardingViewModel extends AsyncNotifier<RoutineSetup> {
  @override
  Future<RoutineSetup> build() {
    return ref.watch(onboardingRepositoryProvider).load();
  }

  void setStudent(bool value) =>
      _update((data) => data.copyWith(isStudent: value));

  void setWorker(bool value) =>
      _update((data) => data.copyWith(isWorker: value));

  void toggleObjective(String objective) {
    _update((data) {
      final objectives = {...data.objectives};
      objectives.contains(objective)
          ? objectives.remove(objective)
          : objectives.add(objective);
      return data.copyWith(objectives: objectives);
    });
  }

  void setWakeMinutes(int value) =>
      _update((data) => data.copyWith(wakeMinutes: value));

  void setSleepMinutes(int value) =>
      _update((data) => data.copyWith(sleepMinutes: value));

  void setMealsMinutes(int value) =>
      _update((data) => data.copyWith(mealsMinutes: value));

  void setRestMinutes(int value) =>
      _update((data) => data.copyWith(restMinutes: value));

  void setCommuteMinutes(int value) =>
      _update((data) => data.copyWith(commuteMinutes: value));

  Future<bool> save() async {
    final setup = state.value;
    if (setup == null) return false;

    try {
      await ref.read(onboardingRepositoryProvider).save(setup);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _update(RoutineSetup Function(RoutineSetup data) transform) {
    final data = state.value;
    if (data != null) state = AsyncData(transform(data));
  }
}

final onboardingViewModelProvider =
    AsyncNotifierProvider<OnboardingViewModel, RoutineSetup>(
      OnboardingViewModel.new,
    );
