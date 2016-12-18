drop type if exists osm_way cascade;
create type osm_way as (
    id          bigint,
    visible     boolean,
    "version"   bigint,
    changeset   bigint,
    "timestamp" timestamp,
    "user"      text,
    uid         bigint,
    tags        osm_tag [],
    nodes       bigint []
);

create function _osm_way_to_xml(
    p_way osm_way
)
    returns xml parallel safe language sql as $$
select
    xmlelement(
        name way,
        xmlattributes (
        (p_way).id as id,
        (p_way).visible as visible,
        (p_way).version as version,
        (p_way).changeset as changeset,
        to_char((p_way).timestamp, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as timestamp,
        (p_way).user as user,
        (p_way).uid as uid
    ),
    (p_way).tags :: xml,
    (
        select xmlagg(
            xmlelement(
                name nd,
                xmlattributes (
                p_node as ref
                )
            ))
        from unnest((p_way).nodes) p_node
    )
)
$$;

drop cast if exists ( osm_way as xml );
create cast ( osm_way as xml )
with function _osm_way_to_xml(osm_way);