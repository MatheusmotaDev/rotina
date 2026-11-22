import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../data/repositories/focus_repository.dart';
import '../../domain/models/focus_session.dart';

final focusRepositoryProvider = Provider<FocusRepository>((ref) {
  return FocusRepository(ref.watch(authRepositoryProvider).client);
});

class FocusViewModel extends AsyncNotifier<FocusSession?> {
  @override
  Future<FocusSession?> build() =>
      ref.watch(focusRepositoryProvider).loadActive();

  Future<bool> start(
    FocusMode mode, {
    String? taskOccurrenceId,
    int? plannedMinutes,
  }) => _run(
    () => ref
        .read(focusRepositoryProvider)
        .start(
          mode: mode,
          taskOccurrenceId: taskOccurrenceId,
          plannedMinutes: plannedMinutes,
        ),
  );

  Future<bool> pause() {
    final session = state.value;
    if (session == null) return Future.value(false);
    return _run(() => ref.read(focusRepositoryProvider).pause(session));
  }

  Future<bool> resume() {
    final session = state.value;
    if (session == null) return Future.value(false);
    return _run(() => ref.read(focusRepositoryProvider).resume(session));
  }

  Future<bool> finish({bool cancelled = false}) {
    final session = state.value;
    if (session == null) return Future.value(false);
    return _run(
      () => ref
          .read(focusRepositoryProvider)
          .finish(session, cancelled: cancelled),
      clear: true,
    );
  }

  Future<bool> _run(
    Future<FocusSession> Function() operation, {
    bool clear = false,
  }) async {
    try {
      final result = await operation();
      state = AsyncData(clear ? null : result);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final focusViewModelProvider =
    AsyncNotifierProvider<FocusViewModel, FocusSession?>(FocusViewModel.new);
