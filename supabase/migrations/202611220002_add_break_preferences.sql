alter table public.pausas
  add column if not exists duracao_planejada_min smallint
    check (duracao_planejada_min between 1 and 720),
  add column if not exists lembrete_ativo boolean not null default false;
