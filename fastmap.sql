-- \timing on
--set enable_hashjoin to off;


\echo '<?xml version="1.0" encoding="UTF-8"?><osm version="0.6" generator="FastMAP" copyright="OpenStreetMap and contributors" attribution="http://www.openstreetmap.org/copyright" license="http://opendatacommons.org/licenses/odbl/1-0/">'
--explain ( analyse, buffers )
copy (
with params as (
    select
        27.61649608612061 :: float  as minlon,
        53.85379229563698 :: float  as minlat,
        27.671985626220707 :: float as maxlon,
        53.886459293813054 :: float as maxlat
), direct_nodes as (
    select n.*
    from
        current_nodes n,
        params p
    where
        point(longitude :: float / 1e7 :: float, latitude :: float / 1e7 :: float) <@
        box(point(minlon, minlat), point(maxlon, maxlat))
        --         and n.latitude between minlat and maxlat
        --         and n.longitude between minlon and maxlon
        and n.visible
), all_request_ways as (
    select
        distinct on (id) w.*
    from
        direct_nodes n
        join current_way_nodes c on (c.node_id = n.id)
        join current_ways w on (w.id = c.way_id)
    where w.visible
    order by id
), all_request_nodes as (
    select n2.*
    from
        all_request_ways w2
        join current_way_nodes c on (c.way_id = w2.id)
        join current_nodes n2 on (n2.id = c.node_id)
    union
    select *
    from direct_nodes
    order by id
), relations_from_ways_and_nodes as (
    select distinct on (id) r.*
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
), all_request_relations as (
    select *
    from relations_from_ways_and_nodes
    union
    select r.*
    from relations_from_ways_and_nodes r2
        join current_relation_members rm on (r2.id = rm.member_id and rm.member_type = 'Relation')
        join current_relations r on (r.id = rm.relation_id)
    order by id
)
select line :: text
from (
         select xmlelement(
             name bounds, xmlattributes (
             minlat,
             minlon,
             maxlat,
             maxlon
         )
     ) as line
from params p
union all
select
    xmlelement(name node,
               xmlattributes (
               id as id,
               visible as visible,
               version as version,
               changeset_id as changeset,
               to_char(timestamp, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as timestamp,
               'FIXME' as user,
               '1' as uid, -- FIXME
               (latitude / 1e7) :: numeric(10, 7) as lat,
               (longitude / 1e7) :: numeric(10, 7) as lon
    ),
    nt.tags
) line
from all_request_nodes n
join lateral (
select xmlagg(xmlelement( name tag,
xmlattributes (k as k, v as v)
) order by k, v) as tags
from current_node_tags t
where t.node_id = n.id
) nt on true
union all
select
    xmlelement(name way,
               xmlattributes (
               id as id,
               version as version,
               to_char(timestamp, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as timestamp,
               visible as visible,
               changeset_id as changeset),
    wt.tags,
    nds.nodes
) line
from all_request_ways w
join lateral (
select xmlagg(xmlelement( name tag,
xmlattributes (k as k, v as v)
) order by k, v) as tags
from current_way_tags t
where t.way_id = w.id
) wt on true
join lateral (
select xmlagg(xmlelement( name nd,
xmlattributes (node_id as ref )
) order by sequence_id) as nodes
from current_way_nodes t
where t.way_id = w.id
) nds on true
union all
select
    xmlelement(name relation,
               xmlattributes (
               id as id,
               version as version,
               to_char(timestamp, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as timestamp,
               visible as visible,
               changeset_id as changeset),
    rt.tags,
    mbr.nodes
) line
from all_request_relations r
join lateral (
select xmlagg(xmlelement( name tag,
xmlattributes (k as k, v as v)
) order by k, v) as tags
from current_relation_tags t
where t.relation_id = r.id
) rt on true
join lateral (
select xmlagg(xmlelement( name member,
xmlattributes (lower(member_type:: text ) as type, member_id as ref, member_role as role )
) order by sequence_id) as nodes
from current_relation_members t
where t.relation_id = r.id
) mbr on true
) n
) to stdout;
;
\echo '</osm>'