import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/home_summary.dart';

final homeViewModelProvider = Provider<HomeSummary>((ref) {
  return const HomeSummary(
    userName: 'Matheus',
    freeMinutes: 630,
    completedTasks: 5,
    totalTasks: 8,
    nextActivityTitle: 'Faculdade',
    nextActivityTime: '18:30 – 21:40',
    checkInCompleted: true,
  );
});
