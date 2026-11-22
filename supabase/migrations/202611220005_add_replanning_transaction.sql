create or replace function public.aplicar_proposta_replanejamento(
  p_proposta_id uuid
) returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_proposta public.propostas_replanejamento%rowtype;
  v_planejamento public.planejamentos_diarios%rowtype;
  v_alteracao public.alteracoes_proposta%rowtype;
  v_titulo text;
begin
  select * into v_proposta
    from public.propostas_replanejamento
    where id = p_proposta_id and usuario_id = (select auth.uid())
    for update;
  if not found or v_proposta.estado <> 'pendente' then
    raise exception 'Proposta indisponível para aplicação';
  end if;

  select * into v_planejamento
    from public.planejamentos_diarios
    where id = v_proposta.planejamento_id
      and usuario_id = (select auth.uid())
    for update;
  if not found or v_planejamento.versao <> v_proposta.versao_base then
    raise exception 'A agenda mudou; gere uma nova proposta';
  end if;

  set constraints blocos_sem_sobreposicao deferred;

  for v_alteracao in
    select * from public.alteracoes_proposta
      where proposta_id = p_proposta_id
        and usuario_id = (select auth.uid())
      order by case acao when 'remover' then 1 when 'mover' then 2 else 3 end
  loop
    if v_alteracao.acao = 'remover' then
      update public.blocos_agenda set estado = 'cancelado', atualizado_em = now()
        where id = v_alteracao.bloco_id
          and planejamento_id = v_planejamento.id
          and usuario_id = (select auth.uid());
    elsif v_alteracao.acao = 'mover' then
      update public.blocos_agenda
        set inicio_em = v_alteracao.novo_inicio_em,
            fim_em = v_alteracao.novo_fim_em,
            atualizado_em = now()
        where id = v_alteracao.bloco_id
          and planejamento_id = v_planejamento.id
          and usuario_id = (select auth.uid());
    else
      select t.titulo into v_titulo
        from public.ocorrencias_tarefas o
        join public.tarefas t on t.id = o.tarefa_id and t.usuario_id = o.usuario_id
        where o.id = v_alteracao.ocorrencia_tarefa_id
          and o.usuario_id = (select auth.uid());
      insert into public.blocos_agenda (
        usuario_id, planejamento_id, data_local, ocorrencia_tarefa_id,
        tipo, titulo, inicio_em, fim_em
      ) values (
        (select auth.uid()), v_planejamento.id, v_planejamento.data_local,
        v_alteracao.ocorrencia_tarefa_id, 'tarefa', v_titulo,
        v_alteracao.novo_inicio_em, v_alteracao.novo_fim_em
      );
    end if;
  end loop;

  update public.planejamentos_diarios
    set versao = versao + 1, estado = 'confirmado', atualizado_em = now()
    where id = v_planejamento.id and usuario_id = (select auth.uid());
  update public.propostas_replanejamento
    set estado = 'aprovada', decidido_em = now()
    where id = p_proposta_id and usuario_id = (select auth.uid());
end;
$$;

revoke all on function public.aplicar_proposta_replanejamento(uuid) from public;
grant execute on function public.aplicar_proposta_replanejamento(uuid) to authenticated;
