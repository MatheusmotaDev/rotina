import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/activity_report.dart';
import '../viewmodels/reports_provider.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  late DateTime _date;
  bool _weekly = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Diário')),
                ButtonSegment(value: true, label: Text('Semanal')),
              ],
              selected: {_weekly},
              onSelectionChanged: (value) =>
                  setState(() => _weekly = value.first),
            ),
          ),
          _DateRow(
            date: _date,
            onPrevious: () => setState(
              () => _date = _date.subtract(Duration(days: _weekly ? 7 : 1)),
            ),
            onNext: () => setState(
              () => _date = _date.add(Duration(days: _weekly ? 7 : 1)),
            ),
          ),
          Expanded(child: _weekly ? _weeklyBody() : _dailyBody()),
        ],
      ),
    );
  }

  Widget _dailyBody() => ref
      .watch(dailyReportProvider(_date))
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            _Retry(onPressed: () => ref.invalidate(dailyReportProvider(_date))),
        data: (report) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(dailyReportProvider(_date)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              _TaskSummary(report: report),
              const SizedBox(height: 12),
              _MetricCard(
                title: 'Tempo das tarefas',
                planned: report.estimatedMinutes,
                actual: report.focusMinutes,
                actualLabel: 'Foco registrado',
              ),
              const SizedBox(height: 12),
              _WakeCard(report: report),
              const SizedBox(height: 12),
              _MetricCard(
                title: 'Descanso',
                planned: null,
                actual: report.restMinutes,
                actualLabel: 'Tempo registrado',
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.lightbulb_outline_rounded),
                  title: const Text('Feedback do dia'),
                  subtitle: Text(report.feedback),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _weeklyBody() => ref
      .watch(weeklyReportProvider(_date))
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Retry(
          onPressed: () => ref.invalidate(weeklyReportProvider(_date)),
        ),
        data: (report) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumo dos últimos 7 dias',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${report.completedTasks} de ${report.totalTasks} tarefas concluídas',
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: report.completionRate ?? 0),
                    const SizedBox(height: 14),
                    Text(
                      '${_minutes(report.focusMinutes)} de foco • ${_minutes(report.restMinutes)} de descanso',
                    ),
                    Text(
                      'Check-in registrado em ${report.checkinDays} de 7 dias',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...report.days.map(
              (day) => Card(
                child: ListTile(
                  title: Text(_shortDate(day.date)),
                  subtitle: Text(
                    '${day.completedTasks}/${day.totalTasks} concluídas • ${_minutes(day.focusMinutes)} de foco',
                  ),
                  trailing: day.actualWake == null
                      ? const Text('Sem check-in')
                      : const Icon(Icons.check_circle_outline_rounded),
                ),
              ),
            ),
          ],
        ),
      );
}

class _TaskSummary extends StatelessWidget {
  const _TaskSummary({required this.report});
  final DailyActivityReport report;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tarefas', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text('${report.completedTasks} concluídas'),
          Text('${report.pendingTasks} pendentes'),
          Text('${report.postponedTasks} adiadas'),
        ],
      ),
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.planned,
    required this.actual,
    required this.actualLabel,
  });
  final String title;
  final int? planned;
  final int actual;
  final String actualLabel;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(title),
      subtitle: Text(
        '${planned == null ? 'Planejado: não informado' : 'Estimado: ${_minutes(planned!)}'}\n$actualLabel: ${_minutes(actual)}',
      ),
    ),
  );
}

class _WakeCard extends StatelessWidget {
  const _WakeCard({required this.report});
  final DailyActivityReport report;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: const Text('Despertar'),
      subtitle: Text(
        report.actualWake == null
            ? 'Planejado: ${_timeFromMinutes(report.plannedWakeMinutes!)}\nReal: não informado'
            : 'Planejado: ${_timeFromMinutes(report.plannedWakeMinutes!)}\nReal: ${_time(report.actualWake!)}',
      ),
    ),
  );
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.date,
    required this.onPrevious,
    required this.onNext,
  });
  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
      Expanded(child: Text(_shortDate(date), textAlign: TextAlign.center)),
      IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
    ],
  );
}

class _Retry extends StatelessWidget {
  const _Retry({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton(
      onPressed: onPressed,
      child: const Text('Tentar novamente'),
    ),
  );
}

String _minutes(int value) =>
    value < 60 ? '$value min' : '${value ~/ 60}h ${value % 60}min';
String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
String _timeFromMinutes(int value) =>
    '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';
String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
