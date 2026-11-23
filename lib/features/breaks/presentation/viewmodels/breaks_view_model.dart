import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../notifications/presentation/viewmodels/notification_preferences_view_model.dart';
import '../../data/repositories/breaks_repository.dart';
import '../../domain/models/break_session.dart';

final breaksRepositoryProvider = Provider<BreaksRepository>((ref) {
  return BreaksRepository(ref.watch(authRepositoryProvider).client);
});

class BreaksViewModel extends AsyncNotifier<List<BreakSession>> {
  @override
  Future<List<BreakSession>> build() =>
      ref.watch(breaksRepositoryProvider).loadRecent();

  Future<bool> start({
    required int plannedMinutes,
    required bool reminderEnabled,
  }) => _run(
    () => ref
        .read(breaksRepositoryProvider)
        .start(
          plannedMinutes: plannedMinutes,
          reminderEnabled: reminderEnabled,
        ),
  );

  Future<bool> finish(BreakSession session) =>
      _run(() => ref.read(breaksRepositoryProvider).finish(session));

  Future<bool> _run(Future<void> Function() operation) async {
    try {
      await operation();
      state = AsyncData(await ref.read(breaksRepositoryProvider).loadRecent());
      try {
        await ref.read(notificationSchedulerProvider).sync();
      } catch (_) {
        // A pausa permanece salva mesmo sem permissão de notificação.
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

final breaksViewModelProvider =
    AsyncNotifierProvider<BreaksViewModel, List<BreakSession>>(
      BreaksViewModel.new,
    );
