import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../checkin/presentation/viewmodels/checkin_view_model.dart';
import '../../../commitments/presentation/viewmodels/commitments_view_model.dart';
import '../../domain/models/daily_availability.dart';
import '../../domain/services/availability_engine.dart';

final availabilityProvider = FutureProvider<DailyAvailability>((ref) async {
  final checkin = await ref.watch(checkinViewModelProvider.future);
  final dailyCommitments = await ref.watch(
    dailyCommitmentsProvider(checkin.date).future,
  );
  final client = ref.watch(authRepositoryProvider).client;
  final user = client.auth.currentUser!;
  final profile = await client
      .from('perfis')
      .select('hora_dormir_padrao,reserva_diaria_min')
      .eq('id', user.id)
      .single();
  final sleepMinutes = _parseTime(profile['hora_dormir_padrao'] as String);
  final awakeStart = checkin.completed
      ? checkin.actualWake
      : DateTime(
          checkin.date.year,
          checkin.date.month,
          checkin.date.day,
          checkin.plannedWakeMinutes ~/ 60,
          checkin.plannedWakeMinutes % 60,
        );
  var awakeEnd = DateTime(
    checkin.date.year,
    checkin.date.month,
    checkin.date.day,
    sleepMinutes ~/ 60,
    sleepMinutes % 60,
  );
  if (!awakeEnd.isAfter(awakeStart)) {
    awakeEnd = awakeEnd.add(const Duration(days: 1));
  }
  final confirmations = {
    for (final commitment in checkin.commitments)
      commitment.id: commitment.confirmed,
  };
  final busy = dailyCommitments
      .where((occurrence) {
        final id = occurrence.source.rowIdsByDay[occurrence.date.weekday]!;
        return confirmations[id] ?? true;
      })
      .map(
        (occurrence) => TimeInterval(
          start: occurrence.occupiedStart,
          end: occurrence.occupiedEnd,
          label: occurrence.source.title,
        ),
      );

  return const AvailabilityEngine().calculate(
    AvailabilityInput(
      awakeStart: awakeStart,
      awakeEnd: awakeEnd,
      busyIntervals: busy.toList(),
      personalReserveMinutes: profile['reserva_diaria_min'] as int,
      provisional: !checkin.completed,
    ),
  );
});

int _parseTime(String value) {
  final parts = value.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}
