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
    select n.id
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
    select distinct c.way_id as id
    from
        direct_nodes n
        join current_way_nodes c on (c.node_id = n.id)
), all_request_nodes as (
    select distinct id
    from (
             select c.node_id as id
             from
                 all_request_ways w
                 join current_way_nodes c on (c.way_id = w.id)
             union
             select n.id
             from direct_nodes n
         ) nodes
), relations_from_ways_and_nodes as (
    select distinct m.relation_id as id
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
), all_request_relations as (
    select r.id
    from relations_from_ways_and_nodes r
    union
    select rm.relation_id
    from relations_from_ways_and_nodes r2
        join current_relation_members rm on (r2.id = rm.member_id and rm.member_type = 'Relation')
)
select line
from (
    -- XML header
    select
        '<?xml version="1.0" encoding="UTF-8"?><osm version="0.6" generator="FastMAP" copyright="OpenStreetMap and contributors" attribution="http://www.openstreetmap.org/copyright" license="http://opendatacommons.org/licenses/odbl/1-0/">' :: text as line
    union all
    -- bounds header
    select xmlelement(name bounds, xmlattributes (minlat, minlon, maxlat, maxlon)) :: text as line
from params p
union all
-- nodes
select line :: text
from (
         select get_node_by_id(n.id) :: xml as line
         from all_request_nodes n
         order by n.id
     ) nodes
union all
-- ways
select line :: text
from (
         select get_way_by_id(w.id) :: xml as line
         from all_request_ways w
         order by w.id
     ) ways
union all
-- relations
select line :: text
from
    (
        select get_relation_by_id(r.id) :: xml as line
        from all_request_relations r
        order by r.id
    ) relations
union all
-- XML footer
select '</osm>'
) repsonse;
commit;