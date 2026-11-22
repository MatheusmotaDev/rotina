alter table public.sessoes_foco
  drop constraint if exists sessoes_foco_estado_check;

alter table public.sessoes_foco
  add column if not exists pausada_em timestamptz,
  add column if not exists duracao_planejada_min smallint
    check (duracao_planejada_min between 1 and 720),
  add column if not exists duracao_pausada_seg integer not null default 0
    check (duracao_pausada_seg >= 0),
  add constraint sessoes_foco_estado_check
    check (estado in ('em_andamento','pausada','concluida','cancelada'));

alter table public.sessoes_foco
  drop constraint if exists sessao_periodo_valido;

alter table public.sessoes_foco
  add constraint sessao_periodo_valido check (
    (estado = 'em_andamento' and fim_em is null and pausada_em is null)
    or (estado = 'pausada' and fim_em is null and pausada_em is not null)
    or (estado in ('concluida','cancelada') and fim_em is not null
      and fim_em > inicio_em and pausada_em is null)
  );
