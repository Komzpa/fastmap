drop function if exists get_relation_by_id( bigint );
create or replace function get_relation_by_id(
    p_id bigint
)
    returns setof osm_relation stable parallel safe language sql as $$
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
        from current_relation_tags t
        where t.relation_id = p_id
    ),
    (
        select array_agg(
            (
                case member_type
                when 'Way'
                    then 'way'
                when 'Relation'
                    then 'relation'
                when 'Node'
                    then 'node'
                end,
                member_id,
                member_role
            ) :: osm_member
        order by sequence_id)
        from current_relation_members t
        where t.relation_id = p_id
    )
from current_relations n
    join changesets c on c.id = n.changeset_id
    left join users u on (u.id = c.user_id and u.data_public)
where n.id = p_id
$$;