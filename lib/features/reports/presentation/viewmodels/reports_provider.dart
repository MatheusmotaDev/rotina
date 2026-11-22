import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../data/repositories/reports_repository.dart';
import '../../domain/models/activity_report.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.watch(authRepositoryProvider).client);
});

final dailyReportProvider =
    FutureProvider.family<DailyActivityReport, DateTime>(
      (ref, date) => ref.watch(reportsRepositoryProvider).loadDaily(date),
    );

final weeklyReportProvider =
    FutureProvider.family<WeeklyActivityReport, DateTime>(
      (ref, date) => ref.watch(reportsRepositoryProvider).loadWeek(date),
    );
