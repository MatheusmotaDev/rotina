create table if not exists public.reservas_pessoais (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.perfis(id) on delete cascade,
  titulo varchar(120) not null check (length(btrim(titulo)) > 0),
  dias_semana smallint[] not null check (
    cardinality(dias_semana) > 0
    and dias_semana <@ array[1,2,3,4,5,6,7]::smallint[]
  ),
  hora_inicio time not null,
  hora_fim time not null,
  ativo boolean not null default true,
  criado_em timestamptz not null default now(),
  constraint reserva_horario_nao_zero check (hora_inicio <> hora_fim),
  unique (usuario_id, id)
);

alter table public.reservas_pessoais enable row level security;

drop policy if exists reservas_pessoais_proprias on public.reservas_pessoais;
create policy reservas_pessoais_proprias on public.reservas_pessoais
  for all to authenticated
  using ((select auth.uid()) = usuario_id)
  with check ((select auth.uid()) = usuario_id);

create index if not exists idx_reservas_pessoais_usuario
  on public.reservas_pessoais(usuario_id) where ativo;
