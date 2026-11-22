create table if not exists public.preparacoes_dia_seguinte (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.perfis(id) on delete cascade,
  data_local date not null,
  acordar_pretendido time not null,
  compromissos_confirmados jsonb not null default '{}'::jsonb,
  confirmado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now(),
  unique (usuario_id, data_local)
);

alter table public.preparacoes_dia_seguinte enable row level security;

drop policy if exists preparacoes_proprias on public.preparacoes_dia_seguinte;
create policy preparacoes_proprias on public.preparacoes_dia_seguinte
  for all to authenticated
  using ((select auth.uid()) = usuario_id)
  with check ((select auth.uid()) = usuario_id);
