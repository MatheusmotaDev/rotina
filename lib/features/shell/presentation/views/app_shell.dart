import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../commitments/presentation/views/commitment_form_page.dart';
import '../../../breaks/presentation/views/breaks_page.dart';
import '../../../focus/presentation/views/focus_page.dart';
import '../../../home/presentation/views/home_page.dart';
import '../../../profile/presentation/views/profile_page.dart';
import '../../../shared/presentation/views/placeholder_page.dart';
import '../../../tasks/presentation/views/task_form_page.dart';
import '../../../tasks/presentation/views/tasks_page.dart';
import '../viewmodels/shell_view_model.dart';

class AppShell extends ConsumerWidget {
  const AppShell({this.authenticated = false, super.key});

  final bool authenticated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(shellViewModelProvider);
    final pages = [
      HomePage(authenticated: authenticated),
      authenticated
          ? const FocusPage()
          : const PlaceholderPage(title: 'Foco', icon: Icons.timer_outlined),
      authenticated
          ? const TasksPage()
          : const PlaceholderPage(
              title: 'Tarefas',
              icon: Icons.check_box_outlined,
            ),
      authenticated
          ? const ProfilePage()
          : const PlaceholderPage(
              title: 'Perfil',
              icon: Icons.person_outline_rounded,
            ),
    ];

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Adicionar',
        backgroundColor: AppColors.primaryStrong,
        foregroundColor: Colors.white,
        onPressed: () => _showCreateMenu(context),
        child: const Icon(Icons.add_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex < 2 ? selectedIndex : selectedIndex + 1,
        onDestinationSelected: (index) {
          if (index == 2) {
            _showCreateMenu(context);
            return;
          }
          ref
              .read(shellViewModelProvider.notifier)
              .selectTab(index < 2 ? index : index - 1);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Hoje',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer_rounded),
            label: 'Foco',
          ),
          NavigationDestination(
            enabled: false,
            icon: SizedBox(width: 36),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_box_outlined),
            selectedIcon: Icon(Icons.check_box_rounded),
            label: 'Tarefas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateMenu(BuildContext pageContext) {
    return showModalBottomSheet<void>(
      context: pageContext,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Adicionar',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.add_task_rounded),
                title: const Text('Nova tarefa'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (authenticated) {
                    Navigator.of(pageContext).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TaskFormPage(),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_rounded),
                title: const Text('Novo compromisso'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(pageContext).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CommitmentFormPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.coffee_rounded),
                title: const Text('Registrar pausa'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (authenticated) {
                    Navigator.of(pageContext).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BreaksPage(),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
