import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/daily_plan.dart';
import '../viewmodels/planning_view_model.dart';

class PlanningPage extends ConsumerWidget {
  const PlanningPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planningViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda de hoje')),
      body: plan.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(planningViewModelProvider),
            child: const Text('Tentar novamente'),
          ),
        ),
        data: (value) => _PlanBody(plan: value),
      ),
    );
  }
}

class _PlanBody extends ConsumerWidget {
  const _PlanBody({required this.plan});

  final DailyPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (plan.state == PlanState.provisional) _InitialProposal(plan: plan),
        if (plan.hasReplanningReason && plan.state == PlanState.confirmed)
          const _Notice(
            text: 'Mudanças no dia podem exigir uma nova organização.',
          ),
        if (plan.proposal != null) _ProposalCard(proposal: plan.proposal!),
        if (plan.state == PlanState.confirmed && plan.proposal == null)
          OutlinedButton.icon(
            onPressed: () => _generate(context, ref),
            icon: const Icon(Icons.auto_fix_high_rounded),
            label: const Text('Gerar proposta de replanejamento'),
          ),
        const SizedBox(height: 20),
        Text('Linha do tempo', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        if (plan.timeline.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('Nenhuma atividade confirmada para hoje.'),
            ),
          )
        else
          ...plan.timeline.map((entry) => _TimelineTile(entry: entry)),
      ],
    );
  }

  Future<void> _generate(BuildContext context, WidgetRef ref) async {
    final saved = await ref
        .read(planningViewModelProvider.notifier)
        .generateProposal();
    if (!saved && context.mounted) _error(context);
  }
}

class _InitialProposal extends ConsumerWidget {
  const _InitialProposal({required this.plan});
  final DailyPlan plan;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Proposta inicial',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text('Revise os horários antes de confirmar a programação.'),
          const SizedBox(height: 12),
          if (plan.draftTasks.isEmpty)
            const Text('Nenhuma tarefa encontrou uma janela disponível.')
          else
            ...plan.draftTasks.map(
              (task) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(task.title),
                trailing: Text('${_time(task.start)}–${_time(task.end)}'),
              ),
            ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () async {
              final saved = await ref
                  .read(planningViewModelProvider.notifier)
                  .confirmInitial();
              if (!saved && context.mounted) _error(context);
            },
            icon: const Icon(Icons.check_rounded),
            label: const Text('Confirmar programação'),
          ),
        ],
      ),
    ),
  );
}

class _ProposalCard extends ConsumerWidget {
  const _ProposalCard({required this.proposal});
  final ReplanningProposal proposal;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Proposta de mudança',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text('A agenda atual permanece intacta até sua aprovação.'),
          const SizedBox(height: 12),
          ...proposal.suggested.map((suggested) {
            final current = proposal.current
                .where((item) => item.occurrenceId == suggested.occurrenceId)
                .firstOrNull;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(suggested.title),
              subtitle: Text(
                'Atual: ${current == null ? 'não agendada' : '${_time(current.start)}–${_time(current.end)}'}\nSugestão: ${_time(suggested.start)}–${_time(suggested.end)}',
              ),
              trailing: IconButton(
                tooltip: 'Ajustar',
                onPressed: suggested.changeId == null
                    ? null
                    : () => _adjust(context, ref, suggested),
                icon: const Icon(Icons.edit_calendar_outlined),
              ),
            );
          }),
          ...proposal.current
              .where(
                (current) => !proposal.suggested.any(
                  (suggested) => suggested.occurrenceId == current.occurrenceId,
                ),
              )
              .map(
                (current) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(current.title),
                  subtitle: Text(
                    'Atual: ${_time(current.start)}–${_time(current.end)}\nSugestão: remover da programação',
                  ),
                ),
              ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _reject(context, ref),
                  child: const Text('Rejeitar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => _approve(context, ref),
                  child: const Text('Aprovar'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _adjust(
    BuildContext context,
    WidgetRef ref,
    PlannedTask task,
  ) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(task.start),
    );
    if (selected == null || !context.mounted) return;
    final start = DateTime(
      task.start.year,
      task.start.month,
      task.start.day,
      selected.hour,
      selected.minute,
    );
    final saved = await ref
        .read(planningViewModelProvider.notifier)
        .adjust(task, start);
    if (!saved && context.mounted) {
      _error(
        context,
        'O horário escolhido causa conflito ou está indisponível.',
      );
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final saved = await ref
        .read(planningViewModelProvider.notifier)
        .rejectProposal();
    if (!saved && context.mounted) _error(context);
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final saved = await ref
        .read(planningViewModelProvider.notifier)
        .approveProposal();
    if (!saved && context.mounted) {
      _error(
        context,
        'A proposta ficou desatualizada ou possui conflito. Gere uma nova sugestão.',
      );
    }
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.entry});
  final TimelineEntry entry;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(_icon(entry.type), color: _color(entry.type)),
      title: Text(entry.title),
      subtitle: Text('${_time(entry.start)}–${_time(entry.end)}'),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.warning.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

void _error(
  BuildContext context, [
  String message = 'Não foi possível salvar a alteração.',
]) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
IconData _icon(TimelineEntryType type) => switch (type) {
  TimelineEntryType.commitment => Icons.event_rounded,
  TimelineEntryType.task => Icons.task_alt_rounded,
  TimelineEntryType.breakTime => Icons.coffee_rounded,
  TimelineEntryType.personal => Icons.person_outline_rounded,
};
Color _color(TimelineEntryType type) => switch (type) {
  TimelineEntryType.commitment => AppColors.primary,
  TimelineEntryType.task => AppColors.success,
  TimelineEntryType.breakTime => AppColors.warning,
  TimelineEntryType.personal => Colors.blueGrey,
};
