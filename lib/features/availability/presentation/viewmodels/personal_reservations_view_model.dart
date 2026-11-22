import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../data/repositories/personal_reservations_repository.dart';
import '../../domain/models/personal_reservation.dart';
import 'availability_provider.dart';

final personalReservationsRepositoryProvider =
    Provider<PersonalReservationsRepository>((ref) {
      return PersonalReservationsRepository(
        ref.watch(authRepositoryProvider).client,
      );
    });

class PersonalReservationsViewModel
    extends AsyncNotifier<List<PersonalReservation>> {
  @override
  Future<List<PersonalReservation>> build() =>
      ref.watch(personalReservationsRepositoryProvider).loadAll();

  Future<bool> create({
    required String title,
    required Set<int> weekdays,
    required int startMinutes,
    required int endMinutes,
  }) => _run(
    () => ref
        .read(personalReservationsRepositoryProvider)
        .create(
          title: title,
          weekdays: weekdays,
          startMinutes: startMinutes,
          endMinutes: endMinutes,
        ),
  );

  Future<bool> delete(String id) =>
      _run(() => ref.read(personalReservationsRepositoryProvider).delete(id));

  Future<bool> _run(Future<void> Function() operation) async {
    try {
      await operation();
      state = AsyncData(
        await ref.read(personalReservationsRepositoryProvider).loadAll(),
      );
      ref.invalidate(availabilityProvider);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final personalReservationsViewModelProvider =
    AsyncNotifierProvider<
      PersonalReservationsViewModel,
      List<PersonalReservation>
    >(PersonalReservationsViewModel.new);
