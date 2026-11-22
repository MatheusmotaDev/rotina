import 'package:flutter_test/flutter_test.dart';
import 'package:rotina/features/reports/domain/services/report_feedback.dart';

void main() {
  const feedback = ReportFeedback();

  test('não presume inatividade sem tarefas registradas', () {
    expect(
      feedback.build(completed: 0, total: 0, tone: 'equilibrado').toLowerCase(),
      contains('não há tarefas'),
    );
  });

  test('tom leve oferece orientação sem punição', () {
    expect(
      feedback.build(completed: 1, total: 4, tone: 'leve'),
      contains('próximo passo'),
    );
  });

  test('resultado alto recebe feedback coerente', () {
    expect(
      feedback.build(completed: 4, total: 5, tone: 'equilibrado'),
      contains('avançou muito bem'),
    );
  });
}
