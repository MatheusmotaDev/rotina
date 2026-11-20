-- MEU RITMO | Modelagem do MVP | Migration inicial para Supabase/PostgreSQL
-- Executar em um projeto Supabase de DESENVOLVIMENTO, não em produção.
-- O schema auth e as roles authenticated/anon são fornecidos pelo Supabase.
-- A migração é deliberadamente de criação inicial (não idempotente).

begin;

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
create extension if not exists btree_gist with schema extensions;
-- Visibiliza operator classes de btree_gist mesmo em PostgreSQL local.
set local search_path = public, extensions, pg_catalog;

-- 01. Perfil e preferências básicas
create table public.perfis (
    id uuid primary key references auth.users(id) on delete cascade,
    nome varchar(120),
    fuso_horario varchar(80) not null default 'UTC',
    hora_acordar_padrao time not null default '08:00',
    hora_dormir_padrao time not null default '23:00',
    reserva_diaria_min smallint not null default 240 check (reserva_diaria_min between 0 and 960),
    nivel_cobranca text not null default 'equilibrado'
       check (nivel_cobranca in ('leve','equilibrado','rigoroso')),
    criado_em timestamptz not null default now(),
    atualizado_em timestamptz not null default now()
);

-- 02. Preferências de lembretes; horários agendados permanecem no dispositivo
create table public.preferencias_notificacoes (
    usuario_id uuid primary key references public.perfis(id) on delete cascade,
    checkin boolean not null default true,
    inicio_tarefas boolean not null default true,
    compromissos boolean not null default true,
    fim_pausa boolean not null default true,
    resumo_noturno boolean not null default true,
    atualizado_em timestamptz not null default now()
);

-- 03. Um registro = um compromisso recorrente em um dia ISO da semana (1=seg ... 7=dom)
-- Horários cruzando a meia-noite são permitidos; o motor trata o dia seguinte.
create table public.compromissos_recorrentes (
    id uuid primary key default gen_random_uuid(),
    usuario_id uuid not null references public.perfis(id) on delete cascade,
    titulo varchar(160) not null check (length(btrim(titulo)) > 0),
    tipo text not null check (tipo in ('trabalho','faculdade','outro')),
    dia_semana smallint not null check (dia_semana between 1 and 7),
    hora_inicio time not null,
    hora_fim time not null,
    deslocamento_antes_min smallint not null default 0 check (deslocamento_antes_min between 0 and 240),
    deslocamento_depois_min smallint not null default 0 check (deslocamento_depois_min between 0 and 240),
    ativo boolean not null default true,
    criado_em timestamptz not null default now(),
    atualizado_em timestamptz not null default now(),
    constraint compromisso_horario_nao_zero check (hora_inicio <> hora_fim),
    unique (usuario_id,id)
);

-- 04. Alterações pontuais (ausência, presença confirmada, alteração de horário)
create table public.excecoes_compromissos (
    id uuid primary key default gen_random_uuid(),
    usuario_id uuid not null references public.perfis(id) on delete cascade,
    compromisso_id uuid not null,
    data_local date not null,
    situacao text not null check (situacao in ('confirmado','cancelado','alterado')),
    inicio_ajustado_em timestamptz,
    fim_ajustado_em timestamptz,
    criado_em timestamptz not null default now(),
    constraint excecao_horario_valido check (
      (situacao = 'alterado' and inicio_ajustado_em is not null and fim_ajustado_em is not null
          and fim_ajustado_em > inicio_ajustado_em)
      or (situacao <> 'alterado' and inicio_ajustado_em is null and fim_ajustado_em is null)
    ),
    unique (usuario_id,compromisso_id,data_local),
    foreign key (usuario_id,compromisso_id)
      references public.compromissos_recorrentes(usuario_id,id) on delete cascade
);

-- 05. Check-in por data local do usuário
create table public.checkins_diarios (
    id uuid primary key default gen_random_uuid(),
    usuario_id uuid not null references public.perfis(id) on delete cascade,
    data_local date not null,
    acordou_em timestamptz not null,
    disposicao text not null check (disposicao in ('baixa','normal','alta')),
    observacao varchar(500),
    criado_em timestamptz not null default now(),
    atualizado_em timestamptz not null default now(),
    unique (usuario_id,data_local)
);

-- 06. Categorias personalizadas de tarefa
create table public.categorias_tarefas (
    id uuid primary key default gen_random_uuid(),
    usuario_id uuid not null references public.perfis(id) on delete cascade,
    nome varchar(60) not null check (length(btrim(nome)) > 0),
    cor varchar(7) check (cor is null or cor ~ '^#[0-9a-fA-F]{6}$'),
    criado_em timestamptz not null default now(),
    unique (usuario_id,nome),
    unique (usuario_id,id)
);

-- 07. Definição de tarefa; recorrência não é uma tarefa concluída
create table public.tarefas (
    id uuid primary key default gen_random_uuid(),
    usuario_id uuid not null references public.perfis(id) on delete cascade,
    categoria_id uuid,
    titulo varchar(180) not null check (length(btrim(titulo)) > 0),
    descricao text,
    prioridade text not null default 'media' check (prioridade in ('baixa','media','alta')),
    duracao_estimada_min smallint not null check (duracao_estimada_min between 5 and 720),
    prazo_em timestamptz,
    data_inicial date not null,
    data_final date,
    repeticao text not null default 'nenhuma' check (repeticao in ('nenhuma','diaria','semanal')),
    dias_semana smallint[] not null default '{}'::smallint[],
    ativo boolean not null default true,
    criado_em timestamptz not null default now(),
    atualizado_em timestamptz not null default now(),
    constraint tarefa_periodo_valido check (data_final is null or data_final >= data_inicial),
    constraint tarefa_recorrencia_valida check (
      dias_semana <@ array[1,2,3,4,5,6,7]::smallint[]
      and (
        (repeticao = 'semanal' and cardinality(dias_semana) > 0)
        or (repeticao in ('nenhuma','diaria') and cardinality(dias_semana) = 0)
      )
    ),
    unique (usuario_id,id),
    foreign key (usuario_id,categoria_id)
      references public.categorias_tarefas(usuario_id,id) on delete set null (categoria_id)
);

-- 08. Ocorrência concreta de cada tarefa no dia, com seu próprio estado
create table public.ocorrencias_tarefas (
    id uuid primary key default gen_random_uuid(),
    usuario_id uuid not null references public.perfis(id) on delete cascade,
    tarefa_id uuid not null,
    data_local date not null,
    estado text not null default 'pendente'
       check (estado in ('pendente','em_andamento','concluida','adiada','cancelada')),
    concluida_em timestamptz,
    criado_em timestamptz not null default now(),
    atualizado_em timestamptz not null default now(),
    constraint ocorrencia_conclusao_consistente check (
      (estado = 'concluida' and concluida_em is not null)
      or (estado <> 'concluida' and concluida_em is null)
    ),
    unique (usuario_id,tarefa_id,data_local),
    unique (usuario_id,id),
    unique (usuario_id,data_local,id),
    foreign key (usuario_id,tarefa_id)
      references public.tarefas(usuario_id,id) on delete cascade
);

-- 09. Contêiner de planejamento diário; não armazena % de tempo livre
create table public.planejamentos_diarios (
    id uuid primary key default gen_random_uuid(),
    usuario_id uuid not null references public.perfis(id) on delete cascade,
    data_local date not null,
    estado text not null default 'provisorio'
       check (estado in ('provisorio','confirmado','encerrado')),
    versao integer not null default 1 check (versao > 0),
    criado_em timestamptz not null default now(),
    atualizado_em timestamptz not null default now(),
    unique (usuario_id,data_local),
    unique (usuario_id,id),
    unique (usuario_id,data_local,id)
);

-- 10. Blocos flexíveis (compromissos fixos vêm das recorrências + exceções)
create table public.blocos_agenda (
    id uuid primary key default gen_random_uuid(),
    usuario_id uuid not null references public.perfis(id) on delete cascade,
    planejamento_id uuid not null,
    data_local date not null,
    ocorrencia_tarefa_id uuid,
    tipo text not null check (tipo in ('tarefa','pausa','pessoal')),
    titulo varchar(180),
    inicio_em timestamptz not null,
    fim_em timestamptz not null,
    estado text not null default 'ativo' check (estado in ('ativo','cancelado')),
    criado_em timestamptz not null default now(),
    atualizado_em timestamptz not null default now(),
    constraint bloco_periodo_valido check (fim_em > inicio_em),
    constraint bloco_tarefa_vinculo check (
      (tipo = 'tarefa' and ocorrencia_tarefa_id is not null)
      or (tipo <> 'tarefa' and ocorrencia_tarefa_id is null)
    ),
    unique (usuario_id,id),
    unique (usuario_id,planejamento_id,id),
    foreign key (usuario_id,data_local,planejamento_id)
      references public.planejamentos_diarios(usuario_id,data_local,id) on delete restrict,
    foreign key (usuario_id,data_local,ocorrencia_tarefa_id)
      references public.ocorrencias_tarefas(usuario_id,data_local,id) on delete restrict,
    constraint blocos_sem_sobreposicao exclude using gist (
       usuario_id with =,
       tstzrange(inicio_em,fim_em,'[)') with &&
    ) where (estado = 'ativo') deferrable initially immediate
);
create unique index blocos_uma_tarefa_ativa
  on public.blocos_agenda(usuario_id,ocorrencia_tarefa_id)
  where ocorrencia_tarefa_id is not null and estado='ativo';

-- 11. Proposta não modifica diretamente os blocos confirmados
create table public.propostas_replanejamento (
    id uuid primary key default gen_random_uuid(),
    usuario_id uuid not null references public.perfis(id) on delete cascade,
    planejamento_id uuid not null,
    versao_base integer not null check (versao_base > 0),
    motivo text not null check (motivo in ('atraso','conflito','mudanca','manual')),
    estado text not null default 'pendente'
       check (estado in ('pendente','aprovada','rejeitada')),
    criado_em timestamptz not null default now(),
    decidido_em timestamptz,
    constraint proposta_decisao_consistente check (
      (estado = 'pendente' and decidido_em is null)
      or (estado <> 'pendente' and decidido_em is not null)
    ),
    unique (usuario_id,id),
    unique (usuario_id,planejamento_id,id),
    foreign key (usuario_id,planejamento_id)
      references public.planejamentos_diarios(usuario_id,id) on delete cascade
);

-- 12. Comparação "antes/depois" da proposta; aplicar em transação no backend/RPC
create table public.alteracoes_proposta (
    id uuid primary key default gen_random_uuid(),
    usuario_id uuid not null references public.perfis(id) on delete cascade,
    proposta_id uuid not null,
    planejamento_id uuid not null,
    data_local date not null,
    bloco_id uuid,
    ocorrencia_tarefa_id uuid,
    acao text not null check (acao in ('mover','remover','inserir')),
    novo_inicio_em timestamptz,
    novo_fim_em timestamptz,
    criado_em timestamptz not null default now(),
    constraint alteracao_formato_valido check (
      (acao='remover' and bloco_id is not null and ocorrencia_tarefa_id is null
        and novo_inicio_em is null and novo_fim_em is null)
      or (acao='mover' and bloco_id is not null and ocorrencia_tarefa_id is null
        and novo_inicio_em is not null and novo_fim_em > novo_inicio_em)
      or (acao='inserir' and bloco_id is null and ocorrencia_tarefa_id is not null
        and novo_inicio_em is not null and novo_fim_em > novo_inicio_em)
    ),
    foreign key (usuario_id,planejamento_id,proposta_id)
      references public.propostas_replanejamento(usuario_id,planejamento_id,id) on delete cascade,
    foreign key (usuario_id,data_local,planejamento_id)
      references public.planejamentos_diarios(usuario_id,data_local,id) on delete restrict,
    foreign key (usuario_id,planejamento_id,bloco_id)
      references public.blocos_agenda(usuario_id,planejamento_id,id) on delete restrict,
    foreign key (usuario_id,data_local,ocorrencia_tarefa_id)
      references public.ocorrencias_tarefas(usuario_id,data_local,id) on delete cascade
);

-- 13. Sessões efetivas de foco (diferentes do tempo planejado)
create table public.sessoes_foco (
    id uuid primary key default gen_random_uuid(),
    usuario_id uuid not null references public.perfis(id) on delete cascade,
    ocorrencia_tarefa_id uuid,
    modo text not null check (modo in ('livre','pomodoro')),
    estado text not null default 'em_andamento'
      check (estado in ('em_andamento','concluida','cancelada')),
    inicio_em timestamptz not null,
    fim_em timestamptz,
    criado_em timestamptz not null default now(),
    constraint sessao_periodo_valido check (
      (estado='em_andamento' and fim_em is null)
      or (estado<>'em_andamento' and fim_em is not null and fim_em>inicio_em)
    ),
    foreign key (usuario_id,ocorrencia_tarefa_id)
      references public.ocorrencias_tarefas(usuario_id,id) on delete set null (ocorrencia_tarefa_id)
);
create unique index sessao_foco_unica_ativa on public.sessoes_foco(usuario_id)
  where estado='em_andamento';

-- 14. Pausas efetivamente realizadas
create table public.pausas (
    id uuid primary key default gen_random_uuid(),
    usuario_id uuid not null references public.perfis(id) on delete cascade,
    bloco_agenda_id uuid,
    tipo text not null check (tipo in ('planejada','espontanea')),
    inicio_em timestamptz not null,
    fim_em timestamptz,
    criado_em timestamptz not null default now(),
    constraint pausa_periodo_valido check (fim_em is null or fim_em>inicio_em),
    foreign key (usuario_id,bloco_agenda_id)
      references public.blocos_agenda(usuario_id,id) on delete set null (bloco_agenda_id)
);
create unique index pausa_unica_ativa on public.pausas(usuario_id) where fim_em is null;

-- Índices para consultas mais comuns do MVP
create index idx_compromissos_dia on public.compromissos_recorrentes(usuario_id,dia_semana) where ativo;
create index idx_excecoes_data on public.excecoes_compromissos(usuario_id,data_local);
create index idx_tarefas_ativas on public.tarefas(usuario_id,ativo);
create index idx_ocorrencias_data on public.ocorrencias_tarefas(usuario_id,data_local);
create index idx_blocos_inicio on public.blocos_agenda(usuario_id,inicio_em);
create index idx_propostas_pendentes on public.propostas_replanejamento(usuario_id,criado_em) where estado='pendente';
create index idx_foco_inicio on public.sessoes_foco(usuario_id,inicio_em desc);
create index idx_pausas_inicio on public.pausas(usuario_id,inicio_em desc);

-- Timestamp de atualização em tabelas editáveis
create function public.definir_atualizado_em()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.atualizado_em = now();
  return new;
end;
$$;

do $$
declare nome_tabela text;
begin
  foreach nome_tabela in array array[
      'perfis','preferencias_notificacoes','compromissos_recorrentes',
      'checkins_diarios','tarefas','ocorrencias_tarefas',
      'planejamentos_diarios','blocos_agenda'
  ] loop
    execute format('create trigger atualizar_timestamp before update on public.%I '
       || 'for each row execute function public.definir_atualizado_em()', nome_tabela);
  end loop;
end $$;

-- RLS: dados comuns podem ser gerenciados pelo proprietário.
-- ATENÇÃO: planejamentos_diarios, blocos_agenda, propostas_replanejamento e alteracoes_proposta
-- são SOMENTE LEITURA para authenticated. Escritas exigem backend confiável,
-- que verifica o JWT e aplica mudanças atomicamente após consentimento.
-- NUNCA use a chave service_role no Flutter. Proteção é obrigatória: uma
-- policy simples de propriedade não garante aprovação do reagendamento.
do $$
declare nome_tabela text;
declare owner_column text;
begin
  foreach nome_tabela in array array[
    'perfis','preferencias_notificacoes','compromissos_recorrentes',
    'excecoes_compromissos','checkins_diarios','categorias_tarefas',
    'tarefas','ocorrencias_tarefas','planejamentos_diarios',
    'blocos_agenda','propostas_replanejamento','alteracoes_proposta',
    'sessoes_foco','pausas'
  ] loop
    owner_column := case when nome_tabela='perfis' then 'id' else 'usuario_id' end;
    execute format('alter table public.%I enable row level security',nome_tabela);
    execute format('revoke all on public.%I from anon, authenticated',nome_tabela);
    if nome_tabela = any(array['planejamentos_diarios','blocos_agenda','propostas_replanejamento','alteracoes_proposta']) then
      execute format('grant select on public.%I to authenticated',nome_tabela);
      execute format('create policy %I on public.%I for select to authenticated using (%I = (select auth.uid()))',
         'leitura_proprietario',nome_tabela,owner_column);
    else
      if nome_tabela = 'perfis' then
        execute format('grant select, insert, update on public.%I to authenticated',nome_tabela);
      else
        execute format('grant select, insert, update, delete on public.%I to authenticated',nome_tabela);
      end if;
      execute format('create policy %I on public.%I for all to authenticated '
         || 'using (%I = (select auth.uid())) with check (%I = (select auth.uid()))',
         'so_proprietario',nome_tabela,owner_column,owner_column);
    end if;
  end loop;
end $$;

commit;
