import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/daily_checkin.dart';
import '../viewmodels/checkin_view_model.dart';

class CheckinPage extends ConsumerStatefulWidget {
  const CheckinPage({super.key});

  @override
  ConsumerState<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends ConsumerState<CheckinPage> {
  final _observationController = TextEditingController();
  bool _observationLoaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _observationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncCheckin = ref.watch(checkinViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in da manhã')),
      body: asyncCheckin.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _ErrorState(
          onRetry: () => ref.invalidate(checkinViewModelProvider),
        ),
        data: (checkin) {
          if (!_observationLoaded) {
            _observationController.text = checkin.observation;
            _observationLoaded = true;
          }
          return _content(checkin);
        },
      ),
    );
  }

  Widget _content(DailyCheckin checkin) {
    final difference = checkin.wakeDifferenceMinutes;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          Text(
            checkin.completed
                ? 'Atualize seu check-in'
                : 'Como seu dia começou?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Essas informações ajustam a disponibilidade sem mover sua agenda automaticamente.',
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              leading: const Icon(
                Icons.wb_sunny_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Horário em que acordou'),
              subtitle: Text(_formatTime(checkin.actualWake)),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _pickWakeTime(checkin),
            ),
          ),
          const SizedBox(height: 10),
          _DifferenceNotice(minutes: difference),
          const SizedBox(height: 24),
          Text(
            'Como está sua disposição?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SegmentedButton<EnergyLevel>(
            segments: const [
              ButtonSegment(
                value: EnergyLevel.low,
                icon: Icon(Icons.battery_1_bar_rounded),
                label: Text('Baixa'),
              ),
              ButtonSegment(
                value: EnergyLevel.normal,
                icon: Icon(Icons.battery_4_bar_rounded),
                label: Text('Normal'),
              ),
              ButtonSegment(
                value: EnergyLevel.high,
                icon: Icon(Icons.battery_full_rounded),
                label: Text('Alta'),
              ),
            ],
            selected: {checkin.energy},
            onSelectionChanged: (values) => ref
                .read(checkinViewModelProvider.notifier)
                .setEnergy(values.first),
          ),
          if (checkin.commitments.isNotEmpty) ...[
            const SizedBox(height: 26),
            Text(
              'Você cumprirá estes compromissos?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < checkin.commitments.length;
                    index++
                  ) ...[
                    SwitchListTile(
                      value: checkin.commitments[index].confirmed,
                      onChanged: (confirmed) => ref
                          .read(checkinViewModelProvider.notifier)
                          .setCommitment(
                            checkin.commitments[index].id,
                            confirmed,
                          ),
                      title: Text(checkin.commitments[index].title),
                      subtitle: Text(
                        '${_formatTime(checkin.commitments[index].start)} – '
                        '${_formatTime(checkin.commitments[index].end)}',
                      ),
                    ),
                    if (index < checkin.commitments.length - 1)
                      const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextField(
            controller: _observationController,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observação opcional',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes_rounded),
            ),
            onChanged: ref
                .read(checkinViewModelProvider.notifier)
                .setObservation,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    checkin.completed
                        ? 'Atualizar check-in'
                        : 'Concluir check-in',
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickWakeTime(DailyCheckin checkin) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(checkin.actualWake),
    );
    if (selected == null) return;
    ref
        .read(checkinViewModelProvider.notifier)
        .setWakeTime(
          DateTime(
            checkin.date.year,
            checkin.date.month,
            checkin.date.day,
            selected.hour,
            selected.minute,
          ),
        );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final saved = await ref.read(checkinViewModelProvider.notifier).save();
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o check-in.')),
      );
    }
  }
}

class _DifferenceNotice extends StatelessWidget {
  const _DifferenceNotice({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final late = minutes > 0;
    final text = minutes == 0
        ? 'Você acordou no horário planejado.'
        : late
        ? 'Você acordou ${_duration(minutes)} depois do planejado.'
        : 'Você acordou ${_duration(minutes.abs())} antes do planejado.';
    final color = minutes == 0
        ? AppColors.success
        : late
        ? AppColors.warning
        : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Tentar novamente'),
      ),
    );
  }
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _duration(int minutes) {
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  if (hours == 0) return '$remainder min';
  if (remainder == 0) return '${hours}h';
  return '${hours}h ${remainder}min';
}
