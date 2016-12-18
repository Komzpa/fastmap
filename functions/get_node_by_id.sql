drop function if exists get_node_by_id( bigint );
create or replace function get_node_by_id(
    p_id bigint
)
    returns setof osm_node stable parallel safe language sql as $$
select
    n.id,
    n.visible,
    n.version,
    n.changeset_id,
    n.timestamp,
    u.display_name,
    u.id,
    n.latitude / 1e7 :: float,
    n.longitude / 1e7 :: float,
    (
        select array_agg(
            (k, v) :: osm_tag
        order by k, v)
        from current_node_tags t
        where t.node_id = p_id
    )
from current_nodes n
    join changesets c on c.id = n.changeset_id
    left join users u on (u.id = c.user_id and u.data_public)
where n.id = p_id
$$;