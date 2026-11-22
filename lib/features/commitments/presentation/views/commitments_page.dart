import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/recurring_commitment.dart';
import '../viewmodels/commitments_view_model.dart';
import 'commitment_exception_page.dart';
import 'commitment_form_page.dart';
import 'daily_commitments_page.dart';

class CommitmentsPage extends ConsumerWidget {
  const CommitmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commitments = ref.watch(commitmentsViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compromissos'),
        actions: [
          IconButton(
            tooltip: 'Ver compromissos do dia',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DailyCommitmentsPage(),
              ),
            ),
            icon: const Icon(Icons.calendar_view_day_outlined),
          ),
        ],
      ),
      body: commitments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _ErrorState(
          onRetry: () => ref.invalidate(commitmentsViewModelProvider),
        ),
        data: (items) => items.isEmpty
            ? _EmptyState(onAdd: () => _openForm(context))
            : RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(commitmentsViewModelProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final commitment = items[index];
                    final hasConflict = items.any(
                      (other) =>
                          !identical(other, commitment) &&
                          commitment.conflictsWith(other),
                    );
                    return _CommitmentCard(
                      commitment: commitment,
                      hasConflict: hasConflict,
                      onEdit: () => _openForm(context, commitment: commitment),
                      onAdjustDate: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              CommitmentExceptionPage(commitment: commitment),
                        ),
                      ),
                      onToggle: (active) =>
                          _toggle(context, ref, commitment, active),
                      onDelete: () => _delete(context, ref, commitment),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Adicionar'),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context, {
    RecurringCommitment? commitment,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CommitmentFormPage(commitment: commitment),
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    RecurringCommitment commitment,
    bool active,
  ) async {
    final saved = await ref
        .read(commitmentsViewModelProvider.notifier)
        .setActive(commitment, active);
    if (!saved && context.mounted) _showError(context);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    RecurringCommitment commitment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir compromisso?'),
        content: Text(
          '“${commitment.title}” será removido de todos os dias selecionados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await ref
        .read(commitmentsViewModelProvider.notifier)
        .delete(commitment);
    if (!deleted && context.mounted) _showError(context);
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível salvar a alteração.')),
    );
  }
}

class _CommitmentCard extends StatelessWidget {
  const _CommitmentCard({
    required this.commitment,
    required this.hasConflict,
    required this.onEdit,
    required this.onAdjustDate,
    required this.onToggle,
    required this.onDelete,
  });

  final RecurringCommitment commitment;
  final bool hasConflict;
  final VoidCallback onEdit;
  final VoidCallback onAdjustDate;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon(commitment.type), color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          commitment.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Switch(value: commitment.active, onChanged: onToggle),
                    ],
                  ),
                  Text(
                    '${_formatTime(commitment.startMinutes)} – ${_formatTime(commitment.endMinutes)}',
                  ),
                  const SizedBox(height: 5),
                  Text(_formatWeekdays(commitment.weekdays)),
                  if (commitment.commuteBeforeMinutes > 0 ||
                      commitment.commuteAfterMinutes > 0) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Deslocamento: ${commitment.commuteBeforeMinutes} min antes, '
                      '${commitment.commuteAfterMinutes} min depois',
                    ),
                  ],
                  if (hasConflict) ...[
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: AppColors.warning,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Conflito de horário',
                          style: TextStyle(color: AppColors.warning),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') return onEdit();
                if (value == 'date') return onAdjustDate();
                onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'date', child: Text('Ajustar uma data')),
                PopupMenuItem(value: 'delete', child: Text('Excluir')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              'Nenhum compromisso',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Adicione trabalho, faculdade ou outro horário recorrente.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar compromisso'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48),
          const SizedBox(height: 12),
          const Text('Não foi possível carregar os compromissos.'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

IconData _typeIcon(CommitmentType type) => switch (type) {
  CommitmentType.work => Icons.work_outline_rounded,
  CommitmentType.college => Icons.school_outlined,
  CommitmentType.other => Icons.event_outlined,
};

String _formatTime(int minutes) {
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatWeekdays(Set<int> days) {
  const labels = {
    1: 'Seg',
    2: 'Ter',
    3: 'Qua',
    4: 'Qui',
    5: 'Sex',
    6: 'Sáb',
    7: 'Dom',
  };
  final sorted = days.toList()..sort();
  return sorted.map((day) => labels[day]).join(', ');
}
