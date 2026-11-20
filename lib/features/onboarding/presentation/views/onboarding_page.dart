import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../domain/models/routine_setup.dart';
import '../viewmodels/onboarding_view_model.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({this.editing = false, super.key});

  final bool editing;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const _stepCount = 4;
  int _step = 0;
  bool _isSaving = false;
  bool _saveFailed = false;

  @override
  Widget build(BuildContext context) {
    final asyncSetup = ref.watch(onboardingViewModelProvider);
    final setup = asyncSetup.value;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.editing,
        title: Text(widget.editing ? 'Editar minha rotina' : 'Sua rotina'),
      ),
      body: setup == null
          ? _LoadingOrError(
              hasError: asyncSetup.hasError,
              onRetry: () => ref.invalidate(onboardingViewModelProvider),
            )
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Etapa ${_step + 1} de $_stepCount'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (_step + 1) / _stepCount,
                          minHeight: 7,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                  ),
                  if (_saveFailed)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Não foi possível salvar. Confira sua conexão e tente novamente.',
                      ),
                    ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: KeyedSubtree(
                        key: ValueKey(_step),
                        child: _stepContent(setup),
                      ),
                    ),
                  ),
                  _NavigationBar(
                    step: _step,
                    stepCount: _stepCount,
                    isSaving: _isSaving,
                    editing: widget.editing,
                    onBack: _step == 0
                        ? null
                        : () => setState(() => _step -= 1),
                    onNext: () => _next(setup),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _stepContent(RoutineSetup setup) {
    final viewModel = ref.read(onboardingViewModelProvider.notifier);
    return switch (_step) {
      0 => _ObjectivesStep(setup: setup, viewModel: viewModel),
      1 => _SleepStep(setup: setup, viewModel: viewModel),
      2 => _ReservesStep(setup: setup, viewModel: viewModel),
      _ => _SummaryStep(setup: setup),
    };
  }

  Future<void> _next(RoutineSetup setup) async {
    if (_step == 0 && setup.objectives.isEmpty) {
      _showMessage('Escolha pelo menos um objetivo.');
      return;
    }
    if (_step < _stepCount - 1) {
      setState(() => _step += 1);
      return;
    }

    setState(() {
      _isSaving = true;
      _saveFailed = false;
    });
    final saved = await ref.read(onboardingViewModelProvider.notifier).save();
    if (mounted) {
      setState(() {
        _isSaving = false;
        _saveFailed = !saved;
      });
    }
    if (!mounted || !saved) return;

    ref.invalidate(authSessionProvider);
    if (widget.editing) {
      Navigator.of(context).pop();
    } else {
      _showMessage('Sua rotina inicial está pronta.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ObjectivesStep extends StatelessWidget {
  const _ObjectivesStep({required this.setup, required this.viewModel});

  static const _objectives = {
    'organização': 'Organizar melhor o dia',
    'estudos': 'Ter constância nos estudos',
    'foco': 'Melhorar meu foco',
    'equilíbrio': 'Equilibrar tarefas e descanso',
  };

  final RoutineSetup setup;
  final OnboardingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
      children: [
        Text(
          'Vamos montar sua rotina',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text('Conte um pouco sobre seu momento e seus objetivos.'),
        const SizedBox(height: 22),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: setup.isStudent,
                onChanged: viewModel.setStudent,
                secondary: const Icon(Icons.school_outlined),
                title: const Text('Você estuda?'),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: setup.isWorker,
                onChanged: viewModel.setWorker,
                secondary: const Icon(Icons.work_outline_rounded),
                title: const Text('Você trabalha?'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'O que você quer melhorar?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _objectives.entries
              .map(
                (entry) => FilterChip(
                  label: Text(entry.value),
                  selected: setup.objectives.contains(entry.key),
                  onSelected: (_) => viewModel.toggleObjective(entry.key),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SleepStep extends StatelessWidget {
  const _SleepStep({required this.setup, required this.viewModel});

  final RoutineSetup setup;
  final OnboardingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
      children: [
        Text(
          'Como é o seu sono?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Use seus horários habituais. Você poderá ajustá-los depois.',
        ),
        const SizedBox(height: 24),
        _TimeCard(
          label: 'Horário de acordar',
          icon: Icons.wb_sunny_outlined,
          minutes: setup.wakeMinutes,
          onTap: () =>
              _pickTime(context, setup.wakeMinutes, viewModel.setWakeMinutes),
        ),
        const SizedBox(height: 14),
        _TimeCard(
          label: 'Horário de dormir',
          icon: Icons.bedtime_outlined,
          minutes: setup.sleepMinutes,
          onTap: () =>
              _pickTime(context, setup.sleepMinutes, viewModel.setSleepMinutes),
        ),
      ],
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    int currentMinutes,
    void Function(int) update,
  ) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: currentMinutes ~/ 60,
        minute: currentMinutes % 60,
      ),
    );
    if (selected != null) update(selected.hour * 60 + selected.minute);
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    required this.label,
    required this.icon,
    required this.minutes,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        subtitle: Text(_formatTime(minutes)),
        trailing: const Icon(Icons.edit_outlined),
        onTap: onTap,
      ),
    );
  }
}

class _ReservesStep extends StatelessWidget {
  const _ReservesStep({required this.setup, required this.viewModel});

  final RoutineSetup setup;
  final OnboardingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
      children: [
        Text(
          'Reserve tempo para você',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Esses períodos não serão tratados como tempo livre para tarefas.',
        ),
        const SizedBox(height: 24),
        _MinuteSelector(
          label: 'Refeições',
          icon: Icons.restaurant_outlined,
          value: setup.mealsMinutes,
          onChanged: viewModel.setMealsMinutes,
        ),
        const SizedBox(height: 14),
        _MinuteSelector(
          label: 'Descanso',
          icon: Icons.self_improvement_rounded,
          value: setup.restMinutes,
          onChanged: viewModel.setRestMinutes,
        ),
        const SizedBox(height: 14),
        _MinuteSelector(
          label: 'Deslocamentos',
          icon: Icons.directions_bus_outlined,
          value: setup.commuteMinutes,
          onChanged: viewModel.setCommuteMinutes,
        ),
      ],
    );
  }
}

class _MinuteSelector extends StatelessWidget {
  const _MinuteSelector({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  static const _options = [0, 15, 30, 45, 60, 90, 120, 150, 180, 240];
  final String label;
  final IconData icon;
  final int value;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: _options.contains(value) ? value : 60,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: _options
          .map(
            (minutes) => DropdownMenuItem(
              value: minutes,
              child: Text(_formatDuration(minutes)),
            ),
          )
          .toList(),
      onChanged: (minutes) {
        if (minutes != null) onChanged(minutes);
      },
    );
  }
}

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({required this.setup});

  final RoutineSetup setup;

  @override
  Widget build(BuildContext context) {
    final commitments = [
      if (setup.isStudent) 'Estudos',
      if (setup.isWorker) 'Trabalho',
      if (!setup.isStudent && !setup.isWorker) 'Sem compromissos informados',
    ].join(' e ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
      children: [
        Text('Pronto!', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('Confira o resumo antes de começar.'),
        const SizedBox(height: 24),
        _SummaryTile(
          icon: Icons.bedtime_outlined,
          title: 'Sono',
          subtitle:
              '${_formatTime(setup.sleepMinutes)} – ${_formatTime(setup.wakeMinutes)}',
        ),
        const SizedBox(height: 12),
        _SummaryTile(
          icon: Icons.event_outlined,
          title: 'Rotina',
          subtitle: commitments,
        ),
        const SizedBox(height: 12),
        _SummaryTile(
          icon: Icons.hourglass_bottom_rounded,
          title: 'Reservas diárias',
          subtitle: _formatDuration(setup.totalReserveMinutes),
        ),
        const SizedBox(height: 12),
        _SummaryTile(
          icon: Icons.flag_outlined,
          title: 'Objetivos',
          subtitle: setup.objectives.map(_objectiveLabel).join(', '),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _NavigationBar extends StatelessWidget {
  const _NavigationBar({
    required this.step,
    required this.stepCount,
    required this.isSaving,
    required this.editing,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final int stepCount;
  final bool isSaving;
  final bool editing;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = step == stepCount - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            OutlinedButton(
              onPressed: isSaving ? null : onBack,
              child: const Text('Voltar'),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: FilledButton(
              onPressed: isSaving ? null : onNext,
              child: isSaving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isLast
                          ? (editing ? 'Salvar alterações' : 'Começar a usar')
                          : 'Continuar',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingOrError extends StatelessWidget {
  const _LoadingOrError({required this.hasError, required this.onRetry});

  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (!hasError) return const Center(child: CircularProgressIndicator());
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48),
            const SizedBox(height: 16),
            const Text('Não foi possível carregar sua rotina.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(int minutes) {
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatDuration(int minutes) {
  if (minutes == 0) return 'Nenhuma reserva';
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  if (hours == 0) return '$remainder min';
  if (remainder == 0) return '${hours}h';
  return '${hours}h ${remainder}min';
}

String _objectiveLabel(String objective) {
  return switch (objective) {
    'estudos' => 'Estudos',
    'foco' => 'Foco',
    'equilíbrio' => 'Equilíbrio',
    _ => 'Organização',
  };
}
