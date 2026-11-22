Rotina — Requisitos do MVP
> **Documento:** Especificação de requisitos do produto  
> **Produto:** Rotina  
> **Versão do produto:** MVP 1.0  
> **Versão deste documento:** 0.1  
> **Data:** 19/11/2026  
> **Plataformas:** Android e iOS  
> **Stack prevista:** Flutter (Dart, Riverpod, MVVM), Supabase Auth e PostgreSQL  
> **Status:** Escopo funcional definido; requisitos detalhados sujeitos à validação durante a implementação.



arquitetura em MVVM (FEATURE-FIRST)
---
1. Visão geral
O Rotina é um aplicativo de organização pessoal que considera os compromissos e as necessidades diárias do usuário para calcular quando há tempo realmente disponível, sugerir a distribuição de tarefas e acompanhar sua execução.
O produto foi pensado para pessoas que conciliam estudos, trabalho, projetos, exercícios, lazer e descanso. Seu diferencial é o planejamento adaptativo com controle do usuário: quando algo muda, o sistema propõe uma reorganização e só altera os horários depois de receber aprovação.
1.1. Objetivo do MVP
Permitir que uma pessoa configure sua rotina, registre tarefas, faça check-in ao acordar, receba sugestões viáveis de planejamento, acompanhe tarefas e pausas, visualize relatórios e se prepare para o dia seguinte.
1.2. Resultado esperado
Ao final de um ciclo diário, o usuário deverá conseguir responder:
Quanto tempo livre realmente tenho hoje?
Quais atividades cabem nos intervalos disponíveis?
O que posso mudar se acordar tarde ou perder uma atividade?
O que foi realizado e o que ficou pendente?
1.3. Convenções
RF: requisito funcional — comportamento que o aplicativo deve oferecer.
RN: regra de negócio — restrição obrigatória da experiência e dos dados.
RNF: requisito não funcional — qualidade, segurança e característica técnica.
CA: critério de aceite — situação que deve funcionar para a entrega ser aceita.
Planejamento: programação prevista para um dia.
Execução: o que efetivamente aconteceu; não deve ser confundido com o planejamento.
Todos os requisitos funcionais abaixo integram o escopo do MVP 1.0, exceto quando houver indicação expressa de que são evoluções futuras.

**Acompanhamento:** ✅ indica requisito implementado no código atual. Itens sem o símbolo permanecem pendentes ou parciais.
---
2. Módulos e requisitos funcionais
MOD01 — Autenticação e onboarding
Código	Requisito funcional
✅ RF001	Permitir o cadastro de conta por e-mail e senha.
✅ RF002	Permitir autenticação, encerramento de sessão e recuperação de acesso por e-mail.
✅ RF003	Apresentar um onboarding na primeira utilização, com perguntas sobre estudo, trabalho e objetivos de organização.
✅ RF004	Permitir cadastrar horários habituais de dormir e acordar.
✅ RF005	Permitir informar necessidades e reservas de tempo, como refeições, descanso e deslocamentos.
✅ RF006	Permitir revisar e editar as informações do onboarding posteriormente.
✅ RF007	Apresentar um resumo da rotina inicial antes do primeiro planejamento.
Critério principal de aceite: após criar a conta e preencher as informações mínimas, o usuário chega à tela Hoje com sua rotina inicial disponível; não precisa refazer o onboarding a cada acesso.
MOD02 — Compromissos fixos e recorrentes
Código	Requisito funcional
✅ RF008	Cadastrar compromissos com título, dias da semana, horário de início e término.
✅ RF009	Permitir criar, consultar, editar, ativar/desativar e excluir compromissos recorrentes.
✅ RF010	Classificar compromissos como obrigatórios ou flexíveis para fins de planejamento.
✅ RF011	Permitir informar deslocamento associado a compromissos.
✅ RF012	Permitir cancelar ou alterar a ocorrência de um compromisso em uma data específica, sem apagar a regra semanal.
✅ RF013	Mostrar os compromissos aplicáveis ao dia e identificar conflitos de horários.
Critério principal de aceite: cadastrar “Faculdade, segunda a sexta, 18h30–21h40” deve reservar esses intervalos nas datas pertinentes. Cancelar apenas uma quarta-feira não exclui o compromisso das demais semanas.
MOD03 — Check-in matinal
Código	Requisito funcional
✅ RF014	Disponibilizar check-in diário para registrar a hora real de despertar.
✅ RF015	Perguntar se o usuário cumprirá os compromissos previstos para o dia (por exemplo, trabalho e faculdade).
✅ RF016	Permitir registrar o nível de disposição do usuário.
✅ RF017	Comparar o despertar real ao planejado e informar a diferença de tempo.
✅ RF018	Permitir atualizar o check-in do dia, preservando os dados necessários à análise do planejamento e da execução.
Critério principal de aceite: se o usuário planejou acordar às 08h e informou 10h, o cálculo de disponibilidade passa a considerar o novo início do período acordado. A agenda já confirmada não é reorganizada automaticamente.
MOD04 — Cálculo de disponibilidade
Código	Requisito funcional
✅ RF019	Calcular o tempo acordado a partir dos horários de sono e despertar usados para o dia.
RF020	Identificar intervalos ocupados por compromissos, deslocamentos e necessidades pessoais reservadas.
✅ RF021	Calcular a duração total e o percentual de tempo disponível em relação ao período acordado.
✅ RF022	Identificar blocos livres de tempo nos quais uma tarefa possa efetivamente caber.
✅ RF023	Atualizar a estimativa de disponibilidade quando o usuário mudar informações ou confirmar exceções de rotina.
RF024	Alertar sobre conflitos, sobrecarga e tarefas que não cabem nos intervalos disponíveis.
Critério principal de aceite: o cálculo não deve contar duas vezes intervalos sobrepostos nem considerar como disponível um período já reservado. A interface deve mostrar horas, percentual e janelas livres.
MOD05 — Gerenciamento de tarefas
Código	Requisito funcional
RF025	Criar tarefas com título e descrição opcional.
RF026	Associar categoria, duração estimada, prioridade e data ou prazo a uma tarefa.
RF027	Permitir tarefas pontuais e recorrentes.
RF028	Listar e filtrar tarefas por data e situação.
RF029	Editar e excluir tarefas, respeitando o histórico de execução registrado.
RF030	Registrar os estados: pendente, em andamento, concluída e adiada.
RF031	Permitir concluir uma ocorrência de tarefa sem concluir indevidamente todas as ocorrências futuras.
RF032	Permitir reagendar uma tarefa manualmente.
RF033	Destacar atividades vencidas, pendentes ou que exigem atenção.
Critério principal de aceite: uma tarefa semanal concluída hoje deve continuar prevista para a próxima semana. Ao concluir ou adiar uma ocorrência, o aplicativo deve refletir o estado correto nas listas e nos relatórios.
MOD06 — Planejamento e replanejamento assistido
Código	Requisito funcional
RF034	Apresentar uma agenda diária em linha do tempo, com compromissos, tarefas e pausas.
RF035	Sugerir horários para tarefas considerando duração, prioridade, prazo e intervalos disponíveis.
RF036	Mostrar a proposta inicial do dia para avaliação antes de confirmar a programação.
RF037	Identificar mudanças que podem exigir replanejamento, como despertar tardio, cancelamento ou tarefa atrasada.
RF038	Gerar uma proposta de replanejamento sem modificar imediatamente a agenda vigente.
RF039	Mostrar, para cada atividade afetada, seu horário atual e o novo horário sugerido.
RF040	Permitir aprovar, rejeitar ou ajustar manualmente a proposta.
RF041	Aplicar as alterações apenas após confirmação do usuário, verificando novamente possíveis conflitos.
RF042	Manter a agenda original se a proposta for rejeitada; refletir o resultado confirmado nas telas e lembretes.
Critério principal de aceite: ao acordar duas horas depois do previsto, o usuário deve conseguir comparar o plano vigente com a sugestão. Escolher Rejeitar não muda os horários; escolher Aprovar aplica somente as alterações confirmadas e válidas.
MOD07 — Modo Foco
Código	Requisito funcional
RF043	Iniciar uma sessão de foco vinculada, opcionalmente, a uma tarefa.
RF044	Oferecer modo Pomodoro com duração padrão de 25 minutos e opção de ajuste.
RF045	Oferecer cronômetro livre.
RF046	Permitir pausar, retomar e encerrar uma sessão.
RF047	Registrar a duração efetiva da sessão para uso nos relatórios.
Critério principal de aceite: uma tarefa estimada em 90 minutos pode receber uma sessão real de 50 minutos sem que isso a marque automaticamente como concluída.
MOD08 — Pausas e descanso
Código	Requisito funcional
RF048	Permitir iniciar e encerrar uma pausa.
RF049	Permitir registrar descanso de duração predefinida ou personalizada.
RF050	Manter o histórico de tempo de descanso realizado.
RF051	Oferecer lembrete opcional para o encerramento da pausa.
Critério principal de aceite: uma pausa registrada deve aparecer no relatório sem ser tratada automaticamente como tarefa não concluída ou falha de produtividade.
MOD09 — Notificações e lembretes
Código	Requisito funcional
RF052	Oferecer lembrete configurável para o check-in da manhã.
RF053	Avisar sobre o início de tarefas e compromissos, respeitando as permissões do sistema operacional.
RF054	Permitir lembretes de pausas e de retorno às atividades.
RF055	Oferecer lembrete noturno para avaliação do dia e preparação de amanhã.
RF056	Permitir ativar ou desativar tipos de notificações e atualizar lembretes após confirmação de mudanças na agenda.
Critério principal de aceite: o aplicativo continua utilizável se o usuário negar permissão de notificações. Um reagendamento apenas sugerido não deve trocar os lembretes da agenda vigente.
MOD10 — Relatórios e acompanhamento
Código	Requisito funcional
RF057	Mostrar um relatório diário com tarefas concluídas, pendentes e adiadas.
RF058	Apresentar tempo estimado das tarefas e tempo realmente registrado em sessões de foco.
RF059	Apresentar o total de descanso registrado e os horários planejado e real de despertar.
RF060	Exibir um resumo semanal simples com tendências de conclusão e regularidade.
RF061	Mostrar feedback baseado em regras e nas informações efetivamente registradas.
Critério principal de aceite: os relatórios devem distinguir planejado, registrado e não informado, sem presumir que uma tarefa foi realizada só porque seu horário passou.
MOD11 — Planejamento do próximo dia
Código	Requisito funcional
RF062	Oferecer, ao encerrar o dia, a preparação da rotina de amanhã.
RF063	Permitir confirmar compromissos de amanhã, como faculdade e trabalho.
RF064	Permitir indicar horário de despertar pretendido e avaliar tarefas pendentes para transferência.
RF065	Exibir uma previsão provisória da disponibilidade de amanhã, a ser revista no check-in seguinte.
Critério principal de aceite: confirmar que amanhã não haverá faculdade deve retirar esse compromisso da previsão daquele dia, sem alterar a regra recorrente da faculdade.
MOD12 — Widget na tela inicial
Código	Requisito funcional
RF066	Disponibilizar widget para Android e iOS, respeitando as capacidades de cada plataforma.
RF067	Exibir a próxima atividade prevista, o horário correspondente e um indicador simples de progresso diário.
RF068	Permitir abrir a área relevante do aplicativo ao tocar no widget.
Critério principal de aceite: após confirmar uma nova agenda e ocorrer a atualização permitida pelo sistema operacional, o widget deve refletir a próxima atividade correta. Não se exige atualização contínua a cada segundo.
---
3. Regras de negócio
Código	Regra
RN001	O usuário controla sua agenda. Uma proposta de replanejamento não altera blocos confirmados até ser aprovada.
RN002	O usuário pode aprovar, rejeitar ou editar manualmente uma proposta antes de aplicá-la.
RN003	Antes de aplicar uma proposta, o sistema verifica se ela ainda é válida e se não existem conflitos novos.
RN004	Compromissos fixos e reservas essenciais são considerados antes de encaixar tarefas flexíveis.
RN005	A disponibilidade é calculada sobre o período acordado, não sobre as 24 horas do dia.
RN006	Intervalos ocupados sobrepostos não podem ser descontados duas vezes do tempo disponível.
RN007	Tempo livre não significa necessariamente um intervalo contínuo: a duração de uma tarefa deve caber no bloco proposto.
RN008	Na ausência de check-in, o planejamento pode ser consultado, mas deve estar identificado como provisório.
RN009	Mudanças na rotina recorrente não devem reescrever o histórico já executado em dias anteriores.
RN010	Cancelar uma ocorrência isolada de compromisso não elimina a recorrência.
RN011	Concluir uma ocorrência de tarefa recorrente não conclui automaticamente todas as futuras.
RN012	O status de tarefa e o tempo registrado em sessões de foco são independentes.
RN013	Pausas e descansos são registrados sem punição automática; necessidades de sono e descanso devem ser respeitadas.
RN014	Feedback sobre atraso ou produtividade terá três tons configuráveis: leve, equilibrado e rigoroso, sem linguagem ofensiva.
RN015	Relatórios usam dados registrados: ausência de registro não equivale a inatividade comprovada.
RN016	O cálculo e as sugestões do MVP devem funcionar sem IA generativa.
RN017	Cada usuário só pode acessar, modificar ou excluir os próprios dados.
RN018	O aplicativo deve tratar corretamente horários que cruzam a meia-noite e o fuso horário configurado.
RN019	Previsões do dia seguinte não substituem o check-in real quando o novo dia começar.
RN020	Lembretes e informações de agenda só mudam após alteração efetivamente confirmada.
3.1. Estados importantes
Tarefa / ocorrência: `pendente` → `em andamento` → `concluída`; também pode ser `adiada`.
Proposta de replanejamento: `pendente` → `aprovada` ou `rejeitada`; uma proposta invalidada por mudanças posteriores não deve ser aplicada sem nova verificação.
Sessão de foco / pausa: `em andamento` → `pausada` (se aplicável) → `encerrada`.
---
4. Requisitos não funcionais
Código	Requisito não funcional
✅ RNF001	Aplicativo mobile desenvolvido em Flutter para Android e iOS.
✅ RNF002	Interface em português do Brasil, com visual dark mode e identidade roxa aprovada para o produto.
✅ RNF003	Utilizar MVVM e Riverpod, mantendo regras de negócio separadas da apresentação.
✅ RNF004	Utilizar Supabase Auth para autenticação e PostgreSQL como banco relacional.
✅ RNF005	Aplicar políticas de Row Level Security (RLS) às tabelas que armazenam dados de usuários.
RNF006	Validar entradas e restringir relacionamentos para impedir acesso cruzado, dados inconsistentes e horários inválidos.
RNF007	Manter o planejamento e os registros persistidos e sincronizáveis entre sessões autenticadas.
RNF008	Exibir estados de carregamento, ausência de dados e falhas de conexão, evitando confirmar ações que não foram salvas.
RNF009	Tratar horários com consistência de fuso, data e transição de dia.
RNF010	Respeitar acessibilidade básica: contraste, navegação compreensível, áreas de toque adequadas e suporte às opções de texto do sistema.
RNF011	Solicitar permissões de notificação apenas quando necessárias e tratar permissões negadas.
RNF012	Minimizar dados pessoais coletados e observar os princípios aplicáveis da LGPD.
RNF013	Proteger ações sensíveis de aprovação de agenda contra aplicação duplicada e condições de concorrência.
RNF014	Permitir testes automatizados do motor de disponibilidade, recorrências e replanejamento independentemente da interface Flutter.
> **Observação técnica:** o cálculo de disponibilidade pode ocorrer no aplicativo, mas a confirmação e persistência de operações que alteram a agenda devem respeitar validações transacionais e autorizações no backend/banco.
---
5. Estrutura de navegação prevista
O MVP terá as seguintes telas ou fluxos principais:
Boas-vindas / autenticação — entrar, cadastrar e recuperar acesso.
Onboarding — perguntas sobre hábitos e objetivos.
Configuração de compromissos — dias, horários e deslocamentos.
Resumo inicial da rotina — revisão antes de começar.
Hoje — tempo disponível, check-in, tarefas e próximos compromissos.
Agenda — linha do tempo com blocos de horários.
Tarefas — listagem, filtros e status.
Criar / editar tarefa — atributos, duração, prioridade e repetição.
Foco — Pomodoro, cronômetro e controle de sessão.
Registrar pausa — duração e acompanhamento.
Relatórios — visão diária e semanal.
Planejar amanhã — confirmação de obrigações e previsão de disponibilidade.
Componentes complementares: tela ou área de configurações, modais de sugestões de replanejamento, feedback, notificações e widget da tela inicial.
---
6. Fluxos essenciais e critérios de aceite
CA01 — Primeiro acesso
Dado um usuário sem conta, quando se cadastrar e preencher o onboarding, então deverá visualizar sua rotina inicial na tela Hoje e conseguir editá-la posteriormente.
CA02 — Compromisso recorrente
Dado um compromisso de faculdade de segunda a sexta, das 18h30 às 21h40, quando o usuário consultar uma terça-feira, então esse intervalo deverá aparecer reservado.
CA03 — Exceção de compromisso
Dado o compromisso recorrente acima, quando o usuário informar que não terá aula em uma quarta-feira específica, então apenas essa data deverá ser ajustada.
CA04 — Check-in atrasado
Dado despertar previsto às 08h, quando o usuário registrar 10h, então a disponibilidade deverá ser recalculada e possíveis impactos apresentados sem mover tarefas automaticamente.
CA05 — Tempo livre por intervalos
Dado dois blocos livres de 30 minutos, quando existir uma tarefa indivisível de 90 minutos, então o sistema não deverá sugerir que ela cabe nesses blocos.
CA06 — Proposta rejeitada
Dada uma sugestão de reorganização, quando o usuário escolher Rejeitar, então os horários confirmados e seus lembretes deverão permanecer inalterados.
CA07 — Proposta aprovada
Dada uma sugestão válida, quando o usuário escolher Aprovar, então somente as alterações apresentadas e confirmadas deverão ser aplicadas, sem conflitos.
CA08 — Tarefa recorrente
Dada uma tarefa semanal, quando o usuário concluir a ocorrência de hoje, então a ocorrência da próxima semana deverá continuar pendente.
CA09 — Foco real versus estimado
Dada uma tarefa estimada em 90 minutos, quando o usuário registrar 50 minutos de foco, então o relatório deverá mostrar os 50 minutos registrados e não assumir conclusão automática.
CA10 — Pausas
Dada uma pausa de 15 minutos, quando o usuário registrar seu término, então o período deverá aparecer no histórico de descanso.
CA11 — Planejamento de amanhã
Dado o compromisso recorrente de faculdade, quando o usuário informar que amanhã não irá à aula, então a previsão de amanhã deverá ser recalculada, sem apagar o compromisso da semana seguinte.
CA12 — Proteção dos dados
Dadas contas de usuários diferentes, quando uma tentar ler ou modificar informações particulares da outra, então a operação deverá ser negada pelas políticas de autorização.
CA13 — Widget e notificações
Dada uma mudança de agenda aprovada, quando a atualização for processada dentro das limitações do dispositivo, então widget e lembretes deverão refletir a programação confirmada; alterações ainda propostas não devem ser tratadas como confirmadas.
---
7. Dados que a solução precisa representar
Esta seção identifica os conceitos de dados necessários aos requisitos; os nomes exatos de tabelas, campos, índices e políticas pertencem à documentação específica do banco.
Usuário e preferências: identidade vinculada à autenticação, metas e configurações.
Rotina recorrente: compromissos, dias, horários e reservas habituais.
Exceções da rotina: alterações válidas para datas específicas.
Check-in diário: horário real de despertar, disposição e confirmações do dia.
Tarefas e ocorrências: definição da tarefa, repetição, prioridade, prazo e estado por data.
Planejamento diário e blocos de agenda: horários efetivamente programados.
Propostas de replanejamento: mudanças sugeridas, decisão e horários afetados.
Sessões de foco: início, fim, pausas e duração registrada.
Descanso: períodos de pausa e duração real.
Preferências de notificação: opções de lembretes e alertas.
Não é necessário persistir todo percentual calculado: relatórios e disponibilidade podem ser derivados dos registros que representam a rotina, o planejamento e a execução.
---
8. Fora do escopo do MVP
Os recursos abaixo ficam para versões futuras e não são pré-requisitos para publicar o MVP 1.0:
Assistente conversacional de IA generativa.
Integração com Google Calendar, Outlook e serviços externos de agenda.
Gestão de equipes, compartilhamento de tarefas e perfis colaborativos.
Gamificação, pontos, níveis e recompensas.
Integração com smartwatches e sensores externos.
Previsões comportamentais avançadas baseadas em IA.
Assinaturas, pagamentos e sistema de monetização complexo.
Ferramentas de gestão financeira ou de projetos corporativos.
---
9. Definição de pronto do MVP
O MVP estará pronto para validação de produto quando:
[✅] O usuário conseguir criar sua conta e cadastrar uma rotina.
[✅] Compromissos recorrentes e exceções funcionarem corretamente.
[✅] O check-in recalcular a disponibilidade sem alterar a agenda automaticamente.
[✅] O motor encontrar janelas livres sem sobreposições e detectar sobrecarga.
[ ] Tarefas pontuais e recorrentes puderem ser criadas e acompanhadas.
[ ] O usuário conseguir aceitar, ajustar ou rejeitar propostas de replanejamento.
[ ] Sessões de foco e descansos forem registrados separadamente do tempo estimado.
[ ] Relatórios diários e semanais mostrarem dados coerentes.
[ ] O planejamento de amanhã puder ser confirmado e revisto no dia seguinte.
[ ] Notificações e widget funcionarem dentro dos limites do sistema operacional.
[ ] RLS, integridade de dados e validações de concorrência forem testadas em PostgreSQL/Supabase real.
[ ] Os fluxos principais tiverem testes automatizados e validação manual em dispositivos.
---
10. Decisões já aprovadas
Nome do produto: Rotina.
Formato: aplicativo Android e iOS.
Identidade visual: profissional, dark mode, tons de roxo.
Persistência: PostgreSQL no Supabase.
Tecnologia mobile: Flutter, Dart, Riverpod e MVVM.
Replanejamento: somente sugestão; o usuário aprova, rejeita ou ajusta antes da aplicação.
MVP sem dependência de IA generativa.
> **Nota:** este documento descreve **o que** o MVP deve fazer. A modelagem SQL, contratos de API e detalhes dos algoritmos deverão ser validados separadamente na documentação técnica, sem alterar o escopo aqui estabelecido.
