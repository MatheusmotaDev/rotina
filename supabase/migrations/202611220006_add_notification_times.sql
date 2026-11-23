alter table public.preferencias_notificacoes
  add column if not exists hora_checkin time not null default '08:00',
  add column if not exists hora_resumo_noturno time not null default '21:00',
  add column if not exists antecedencia_inicio_min smallint not null default 10
    check (antecedencia_inicio_min between 0 and 120);
