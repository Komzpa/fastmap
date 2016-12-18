drop type if exists osm_node cascade;
create type osm_node as (
    id          bigint,
    visible     boolean,
    "version"   bigint,
    changeset   bigint,
    "timestamp" timestamp,
    "user"      text,
    uid         bigint,
    lat         float,
    lon         float,
    tags        osm_tag []
);

create function _osm_node_to_xml(
    p_node osm_node
)
    returns xml stable parallel safe language sql as $$
select
    xmlelement(
        name node,
        xmlattributes (
        (p_node).id as id,
        (p_node).visible as visible,
        (p_node).version as version,
        (p_node).changeset as changeset,
        to_char((p_node).timestamp, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as timestamp,
        (p_node).user as user,
        (p_node).uid as uid,
        (p_node).lat :: numeric(10, 7) as lat,
        (p_node).lon :: numeric(10, 7) as lon
    ),
    (p_node).tags :: xml
)
$$;

drop cast if exists ( osm_node as xml );
create cast ( osm_node as xml )
with function _osm_node_to_xml(osm_node);