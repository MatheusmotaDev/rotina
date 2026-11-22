import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../viewmodels/availability_provider.dart';
import 'availability_page.dart';

class AvailabilityHomeCard extends ConsumerWidget {
  const AvailabilityHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(availabilityProvider);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AvailabilityPage()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: availability.when(
            loading: () => const SizedBox(
              height: 90,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const SizedBox(
              height: 90,
              child: Center(
                child: Text('Não foi possível calcular seu tempo livre.'),
              ),
            ),
            data: (value) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      value.provisional
                          ? 'Tempo livre previsto'
                          : 'Tempo livre hoje',
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        _duration(value.availableMinutes),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontSize: 36),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        '${(value.freePercentage * 100).round()}%',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: value.freePercentage,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: AppColors.surfaceElevated,
                ),
                if (value.provisional) ...[
                  const SizedBox(height: 10),
                  const Text('Faça o check-in para atualizar esta estimativa.'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _duration(int minutes) {
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  if (hours == 0) return '${remainder}min';
  if (remainder == 0) return '${hours}h';
  return '${hours}h ${remainder}min';
}
