drop function if exists get_way_by_id( bigint );
create or replace function get_way_by_id(
    p_id bigint
)
    returns setof osm_way parallel safe language sql as $$
select
    n.id,
    n.visible,
    n.version,
    n.changeset_id,
    n.timestamp,
    u.display_name,
    u.id,
    (
        select array_agg(
            (k, v) :: osm_tag
        order by k, v)
        from current_way_tags t
        where t.way_id = p_id
    ),
    (
        select array_agg(node_id
        order by sequence_id)
        from current_way_nodes t
        where t.way_id = p_id
    )
from current_ways n
    join changesets c on c.id = n.changeset_id
    left join users u on (u.id = c.user_id and u.data_public)
where n.id = p_id
$$;