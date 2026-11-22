begin;

alter table public.compromissos_recorrentes
  add column if not exists obrigatorio boolean not null default true;

comment on column public.compromissos_recorrentes.obrigatorio is
  'Indica se o compromisso deve ser preservado ou pode participar de sugestões de ajuste.';

commit;
