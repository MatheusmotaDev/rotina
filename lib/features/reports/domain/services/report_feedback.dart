class ReportFeedback {
  const ReportFeedback();

  String build({
    required int completed,
    required int total,
    required String tone,
  }) {
    if (total == 0) {
      return 'Não há tarefas registradas para avaliar neste dia.';
    }
    final rate = completed / total;
    if (rate >= 0.8) {
      return tone == 'rigoroso'
          ? 'Ótimo resultado. Revise o que falta e preserve a consistência.'
          : 'Você avançou muito bem. Celebre o progresso e mantenha o ritmo.';
    }
    if (rate >= 0.5) {
      return tone == 'leve'
          ? 'Houve progresso. Reorganize com calma o que ficou pendente.'
          : 'Bom avanço. Priorize as pendências mais importantes no próximo ciclo.';
    }
    return tone == 'rigoroso'
        ? 'Poucas tarefas foram concluídas. Reduza a carga e redefina prioridades.'
        : 'Hoje foi mais difícil. Escolha um próximo passo pequeno e possível.';
  }
}
