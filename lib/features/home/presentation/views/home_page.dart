import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../availability/presentation/views/availability_home_card.dart';
import '../../../checkin/presentation/views/checkin_home_card.dart';
import '../../../tomorrow/presentation/views/tomorrow_page.dart';
import '../../../planning/presentation/views/planning_page.dart';
import '../viewmodels/home_view_model.dart';

class HomePage extends ConsumerWidget {
  const HomePage({this.authenticated = false, super.key});

  final bool authenticated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(homeViewModelProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_available_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text('Rotina', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                tooltip: 'Notificações',
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Bom dia, ${summary.userName}! 👋',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          const Text('Veja como está o seu dia.'),
          const SizedBox(height: 22),
          if (authenticated)
            const AvailabilityHomeCard()
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tempo livre hoje'),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            summary.formattedFreeTime,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontSize: 36),
                          ),
                        ),
                        _ProgressBadge(value: summary.progress),
                      ],
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: summary.progress,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(8),
                      backgroundColor: AppColors.surfaceElevated,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${summary.completedTasks} de ${summary.totalTasks} atividades concluídas',
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),
          _InfoCard(
            label: 'Próxima atividade',
            title: summary.nextActivityTitle,
            subtitle: summary.nextActivityTime,
            icon: Icons.school_outlined,
            iconColor: AppColors.primary,
          ),
          const SizedBox(height: 14),
          if (authenticated) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.view_timeline_outlined),
                title: const Text('Agenda de hoje'),
                subtitle: const Text('Veja e ajuste a programação confirmada.'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PlanningPage()),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (authenticated)
            const CheckinHomeCard()
          else
            _InfoCard(
              label: 'Check-in da manhã',
              title: summary.checkInCompleted
                  ? 'Concluído às 08:00'
                  : 'Pendente',
              subtitle: summary.checkInCompleted
                  ? 'Seu planejamento considera o horário real.'
                  : 'Conte como o seu dia começou.',
              icon: summary.checkInCompleted
                  ? Icons.check_circle_outline_rounded
                  : Icons.wb_sunny_outlined,
              iconColor: summary.checkInCompleted
                  ? AppColors.success
                  : AppColors.warning,
            ),
          if (authenticated) ...[
            const SizedBox(height: 14),
            Card(
              child: ListTile(
                leading: const Icon(Icons.next_plan_outlined),
                title: const Text('Planejar amanhã'),
                subtitle: const Text('Confirme compromissos e pendências.'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const TomorrowPage()),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${(value * 100).round()}%',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 3),
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
