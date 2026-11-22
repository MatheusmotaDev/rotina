import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../data/repositories/tasks_repository.dart';
import '../../domain/models/task_item.dart';

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepository(ref.watch(authRepositoryProvider).client);
});

final taskCategoriesProvider = FutureProvider<List<TaskCategory>>((ref) {
  return ref.watch(tasksRepositoryProvider).loadCategories();
});

class TasksViewModel extends AsyncNotifier<List<TaskItem>> {
  TasksViewModel(this.date);

  final DateTime date;

  @override
  Future<List<TaskItem>> build() {
    return ref.watch(tasksRepositoryProvider).loadForDate(date);
  }

  Future<bool> setStatus(TaskItem task, TaskStatus status) {
    return _run(
      () => ref.read(tasksRepositoryProvider).setStatus(task, status),
    );
  }

  Future<bool> reschedule(TaskItem task, DateTime date) {
    return _run(() => ref.read(tasksRepositoryProvider).reschedule(task, date));
  }

  Future<bool> delete(TaskItem task) {
    return _run(() => ref.read(tasksRepositoryProvider).delete(task));
  }

  Future<bool> _run(Future<void> Function() operation) async {
    try {
      await operation();
      state = AsyncData(
        await ref.read(tasksRepositoryProvider).loadForDate(date),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final tasksViewModelProvider =
    AsyncNotifierProvider.family<TasksViewModel, List<TaskItem>, DateTime>(
      TasksViewModel.new,
    );
