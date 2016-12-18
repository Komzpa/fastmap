drop function if exists get_nodes_by_box( float, float, float, float );
create or replace function get_nodes_by_box(
    minlon float,
    minlat float,
    maxlon float,
    maxlat float
)
    returns setof osm_node stable parallel safe language sql as $$
select distinct
    n.id,
    n.visible,
    n.version,
    n.changeset_id,
    n.timestamp,
    u.display_name,
    u.id,
    n.latitude / 1e7 :: float,
    n.longitude / 1e7 :: float,
    t.tags
from current_nodes n
    join changesets c on c.id = n.changeset_id
    left join users u on (u.id = c.user_id and u.data_public)
    join lateral (
         select array_agg(
                    (k, v) :: osm_tag
                order by k) as tags
         from current_node_tags t
         where t.node_id = n.id
         ) t on true
where
    point(longitude :: float / 1e7 :: float, latitude :: float / 1e7 :: float) <@
    box(point(minlon, minlat), point(maxlon, maxlat))
    and n.visible
$$;