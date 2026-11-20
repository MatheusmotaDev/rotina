import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotina/app/rotina_app.dart';

void main() {
  testWidgets('exibe o resumo da tela Hoje', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RotinaApp()));

    expect(find.text('Rotina'), findsOneWidget);
    expect(find.text('Bom dia, Matheus! 👋'), findsOneWidget);
    expect(find.text('10h 30min'), findsOneWidget);
    expect(find.text('Faculdade'), findsOneWidget);
  });

  testWidgets('navega para a área de tarefas', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RotinaApp()));

    await tester.tap(find.text('Tarefas'));
    await tester.pumpAndSettle();

    expect(
      find.text('Esta área será implementada no próximo ciclo.'),
      findsOneWidget,
    );
  });
}
