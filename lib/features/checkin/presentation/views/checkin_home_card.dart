import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../viewmodels/checkin_view_model.dart';
import 'checkin_page.dart';

class CheckinHomeCard extends ConsumerWidget {
  const CheckinHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkin = ref.watch(checkinViewModelProvider);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const CheckinPage())),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: checkin.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Row(
              children: [
                Icon(Icons.cloud_off_rounded),
                SizedBox(width: 12),
                Expanded(child: Text('Não foi possível carregar o check-in.')),
              ],
            ),
            data: (value) => Row(
              children: [
                Icon(
                  value.completed
                      ? Icons.check_circle_outline_rounded
                      : Icons.wb_sunny_outlined,
                  color: value.completed
                      ? AppColors.success
                      : AppColors.warning,
                  size: 38,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Check-in da manhã'),
                      const SizedBox(height: 3),
                      Text(
                        value.completed
                            ? 'Concluído às ${_formatTime(value.actualWake)}'
                            : 'Conte como seu dia começou',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
