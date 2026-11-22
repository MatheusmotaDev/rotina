import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/daily_commitment.dart';
import '../viewmodels/commitments_view_model.dart';

class DailyCommitmentsPage extends ConsumerStatefulWidget {
  const DailyCommitmentsPage({super.key});

  @override
  ConsumerState<DailyCommitmentsPage> createState() =>
      _DailyCommitmentsPageState();
}

class _DailyCommitmentsPageState extends ConsumerState<DailyCommitmentsPage> {
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final daily = ref.watch(dailyCommitmentsProvider(_date));
    return Scaffold(
      appBar: AppBar(title: const Text('Compromissos do dia')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Dia anterior',
                  onPressed: () => _changeDay(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(_formatDate(_date)),
                  ),
                ),
                IconButton(
                  tooltip: 'Próximo dia',
                  onPressed: () => _changeDay(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: daily.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(dailyCommitmentsProvider(_date)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tentar novamente'),
                ),
              ),
              data: (items) => items.isEmpty
                  ? const _EmptyDay()
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(dailyCommitmentsProvider(_date)),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final conflict = items.any(
                            (other) =>
                                !identical(item, other) &&
                                item.conflictsWith(other),
                          );
                          return _DailyCard(item: item, conflict: conflict);
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _changeDay(int offset) {
    setState(() => _date = _date.add(Duration(days: offset)));
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selected != null) {
      setState(
        () => _date = DateTime(selected.year, selected.month, selected.day),
      );
    }
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.item, required this.conflict});

  final DailyCommitment item;
  final bool conflict;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 58,
              child: Text(
                _formatTime(item.start),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.source.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text('${_formatTime(item.start)} – ${_formatTime(item.end)}'),
                  if (item.changedForDate) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Horário alterado para esta data',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                  if (conflict) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Conflito de horário',
                      style: TextStyle(color: AppColors.warning),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_available_outlined, size: 54),
          const SizedBox(height: 14),
          Text(
            'Nenhum compromisso neste dia',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const weekdays = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
  return '${weekdays[date.weekday - 1]}, ${date.day}/${date.month}/${date.year}';
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
