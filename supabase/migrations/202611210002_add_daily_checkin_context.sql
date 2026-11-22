begin;

alter table public.checkins_diarios
  add column if not exists acordar_planejado time,
  add column if not exists compromissos_confirmados jsonb not null default '{}'::jsonb;

update public.checkins_diarios as checkin
set acordar_planejado = perfil.hora_acordar_padrao
from public.perfis as perfil
where perfil.id = checkin.usuario_id
  and checkin.acordar_planejado is null;

alter table public.checkins_diarios
  alter column acordar_planejado set default '08:00',
  alter column acordar_planejado set not null;

alter table public.checkins_diarios
  add constraint checkin_compromissos_objeto
  check (jsonb_typeof(compromissos_confirmados) = 'object');

create table public.historico_checkins (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.perfis(id) on delete cascade,
  checkin_id uuid not null references public.checkins_diarios(id) on delete cascade,
  acordou_em timestamptz not null,
  acordar_planejado time not null,
  disposicao text not null check (disposicao in ('baixa','normal','alta')),
  compromissos_confirmados jsonb not null,
  observacao varchar(500),
  registrado_em timestamptz not null default now()
);

create index idx_historico_checkins
  on public.historico_checkins(usuario_id,checkin_id,registrado_em desc);

alter table public.historico_checkins enable row level security;
revoke all on public.historico_checkins from anon, authenticated;
grant select on public.historico_checkins to authenticated;
create policy leitura_proprietario on public.historico_checkins
  for select to authenticated
  using (usuario_id = (select auth.uid()));

create function public.preservar_checkin_anterior()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.historico_checkins (
    usuario_id, checkin_id, acordou_em, acordar_planejado,
    disposicao, compromissos_confirmados, observacao
  ) values (
    old.usuario_id, old.id, old.acordou_em, old.acordar_planejado,
    old.disposicao, old.compromissos_confirmados, old.observacao
  );
  return new;
end;
$$;

create trigger preservar_versao_checkin
before update on public.checkins_diarios
for each row execute function public.preservar_checkin_anterior();

commit;
