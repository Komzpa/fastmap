--- Tunables for debugging
--\timing on
--set enable_hashjoin to off;
--set enable_seqscan to off;

\pset border 0
\pset format unaligned
\pset tuples_only on
begin read only;
-- This one is for debugging using http://tatiyants.com/pev/#/plans/new
--#explain ( analyze, costs, verbose, buffers, format json )
--explain ( analyze, costs, verbose, buffers )
with params as (
    select
        27.61649608612061 :: float  as minlon,
        53.85379229563698 :: float  as minlat,
        27.671985626220707 :: float as maxlon,
        53.886459293813054 :: float as maxlat
), direct_nodes as (
    select n.id, n.visible, n.version, n.changeset_id, n.timestamp, n.latitude, n.longitude
    from
        current_nodes n,
        params p
    where
        point(longitude :: float / 1e7 :: float, latitude :: float / 1e7 :: float) <@
        box(point(minlon, minlat), point(maxlon, maxlat))
        -- and n.tile in (...) - dropped in favor of SP-GiST, can be returned
        --         and n.latitude between minlat and maxlat
        --         and n.longitude between minlon and maxlon
        and n.visible
), all_request_ways as (
    select
        distinct on (id) w.id, w.visible, w.version, w.changeset_id, w.timestamp
    from
        direct_nodes n
        join current_way_nodes c on (c.node_id = n.id)
        join current_ways w on (w.id = c.way_id)
    where w.visible
), all_request_nodes as (
    select n.id, n.visible, n.version, n.changeset_id, n.timestamp, n.latitude, n.longitude
    from
        all_request_ways w
        join current_way_nodes c on (c.way_id = w.id)
        join current_nodes n on (n.id = c.node_id)
    union
    select n.id, n.visible, n.version, n.changeset_id, n.timestamp, n.latitude, n.longitude
    from direct_nodes n
), relations_from_ways_and_nodes as (
    select distinct on (id) r.id, r.visible, r.version, r.changeset_id, r.timestamp
    from
        (
            select
                id,
                'Way' :: nwr_enum as type
            from all_request_ways
            union all
            select
                id,
                'Node' :: nwr_enum as type
            from all_request_nodes
        ) wn
        join current_relation_members m on (wn.id = m.member_id and wn.type = m.member_type)
        join current_relations r on (m.relation_id = r.id)
        where r.visible
), all_request_relations as (
    select r.id, r.visible, r.version, r.changeset_id, r.timestamp
    from relations_from_ways_and_nodes r
    union
    select r.id, r.visible, r.version, r.changeset_id, r.timestamp
    from relations_from_ways_and_nodes r2
        join current_relation_members rm on (r2.id = rm.member_id and rm.member_type = 'Relation')
        join current_relations r on (r.id = rm.relation_id)
    where r.visible
), all_request_users as (
    select
        distinct on (changeset_id)
        changeset_id,
        u.display_name as name,
        u.id           as uid
    from
        ( -- we first know about all the ways, that's why they're earlier in union
            select changeset_id
            from all_request_ways
            union
            select changeset_id
            from all_request_nodes
            union
            select changeset_id
            from all_request_relations
        ) as rc
        join changesets c on (rc.changeset_id = c.id)
        left join users u on (c.user_id = u.id and u.data_public)
    order by changeset_id
)
select line
from (
    -- XML header
    select '<?xml version="1.0" encoding="UTF-8"?><osm version="0.6" generator="FastMAP" copyright="OpenStreetMap and contributors" attribution="http://www.openstreetmap.org/copyright" license="http://opendatacommons.org/licenses/odbl/1-0/">' :: text as line
    union all
    -- bounds header
    select xmlelement(name bounds, xmlattributes(minlat, minlon, maxlat, maxlon)) :: text as line
    from params p
    union all
    -- nodes
    select line :: text
    from (
         select
             xmlelement(
                 name node,
                 xmlattributes(
                     id                                               as id,
                     visible                                          as visible,
                     version                                          as version,
                     n.changeset_id                                   as changeset,
                     to_char(timestamp, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as timestamp,
                     u.name                                           as user,
                     u.uid                                            as uid,
                     (latitude / 1e7) :: numeric(10, 7)               as lat,
                     (longitude / 1e7) :: numeric(10, 7)              as lon
                 ),
                 nt.tags
             ) line
        from all_request_nodes n
        join all_request_users u on (n.changeset_id = u.changeset_id)
        join lateral (
            select xmlagg(
                xmlelement(
                    name tag,
                    xmlattributes(
                        k as k,
                        v as v
                    )
                )
            ) as tags
            from current_node_tags t
            where t.node_id = n.id
        ) nt on true
        order by n.id
    ) nodes
    union all
    -- ways
    select line :: text
    from (
        select
            xmlelement(
                name way,
                xmlattributes(
                    id                                               as id,
                    visible                                          as visible,
                    version                                          as version,
                    w.changeset_id                                   as changeset,
                    to_char(timestamp, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as timestamp,
                    u.name                                           as user,
                    u.uid                                            as uid
                ),
                wt.tags,
                nds.nodes
            ) as line
        from all_request_ways w
        join all_request_users u on ( w.changeset_id = u.changeset_id)
        join lateral (
            select xmlagg(
                xmlelement(
                    name tag,
                    xmlattributes(
                        k as k,
                        v as v
                    )
                )
            ) as tags
            from current_way_tags t
            where t.way_id = w.id
        ) wt on true
        join lateral (
            select xmlagg(
                xmlelement(
                    name nd,
                    xmlattributes(
                        node_id as ref
                    )
                )
                order by sequence_id
            ) as nodes
            from current_way_nodes t
            where t.way_id = w.id
        ) nds on true
        order by w.id
    ) ways
    union all
    -- relations
    select line :: text
    from
    (
        select
            xmlelement(
                name relation,
                xmlattributes(
                    id                                               as id,
                    visible                                          as visible,
                    version                                          as version,
                    r.changeset_id                                   as changeset,
                    to_char(timestamp, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as timestamp,
                    u.name                                           as user,
                    u.uid                                            as uid
                ),
                rt.tags,
                mbr.nodes
            ) line
        from all_request_relations r
        join all_request_users u on (r.changeset_id = u.changeset_id)
        join lateral (
            select xmlagg(
                xmlelement(
                    name tag,
                    xmlattributes(
                        k as k,
                        v as v
                    )
                )
            ) as tags
            from current_relation_tags t
            where t.relation_id = r.id
        ) rt on true
        join lateral (
            select xmlagg(
                xmlelement(
                    name member,
                    xmlattributes (
                        case member_type
                            when 'Way' then 'way'
                            when 'Relation' then 'relation'
                            when 'Node' then 'node'
                        end         as type,
                        member_id   as ref,
                        member_role as role
                    )
                )
                order by sequence_id
            ) as nodes
            from current_relation_members t
            where t.relation_id = r.id
        ) mbr on true
        order by r.id
    ) relations
    union all
    -- XML footer
    select '</osm>'
) repsonse;
commit;