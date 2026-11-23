import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../data/repositories/notification_preferences_repository.dart';
import '../../data/services/local_notification_service.dart';
import '../../data/services/notification_scheduler.dart';
import '../../domain/models/notification_preferences.dart';

final localNotificationServiceProvider = Provider<LocalNotificationService>(
  (_) => LocalNotificationService.instance,
);

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler(
    ref.watch(authRepositoryProvider).client,
    ref.watch(localNotificationServiceProvider),
  );
});

final notificationPreferencesRepositoryProvider =
    Provider<NotificationPreferencesRepository>((ref) {
      return NotificationPreferencesRepository(
        ref.watch(authRepositoryProvider).client,
      );
    });

class NotificationPreferencesViewModel
    extends AsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() =>
      ref.watch(notificationPreferencesRepositoryProvider).load();

  void setPreferences(NotificationPreferences value) =>
      state = AsyncData(value);

  Future<bool> requestPermission() =>
      ref.read(localNotificationServiceProvider).requestPermission();

  Future<bool> save() async {
    final value = state.value;
    if (value == null) return false;
    try {
      await ref.read(notificationPreferencesRepositoryProvider).save(value);
      try {
        await ref.read(notificationSchedulerProvider).sync();
      } catch (_) {
        // Preferências persistidas; permissões negadas não bloqueiam o app.
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

final notificationPreferencesViewModelProvider =
    AsyncNotifierProvider<
      NotificationPreferencesViewModel,
      NotificationPreferences
    >(NotificationPreferencesViewModel.new);
