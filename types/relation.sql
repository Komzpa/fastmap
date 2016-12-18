drop type if exists osm_relation cascade;
create type osm_relation as (
    id          bigint,
    visible     boolean,
    "version"   bigint,
    changeset   bigint,
    "timestamp" timestamp,
    "user"      text,
    uid         bigint,
    tags        osm_tag [],
    members     osm_member []
);

create function _osm_relation_to_xml(
    p_relation osm_relation
)
    returns xml stable parallel safe language sql as $$
select
    xmlelement(
        name relation,
        xmlattributes (
        (p_relation).id as id,
        (p_relation).visible as visible,
        (p_relation).version as version,
        (p_relation).changeset as changeset,
        to_char((p_relation).timestamp, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as timestamp,
        (p_relation).user as user,
        (p_relation).uid as uid
    ),
    (p_relation).tags :: xml,
    (p_relation).members :: xml
)
$$;

drop cast if exists ( osm_relation as xml );
create cast ( osm_relation as xml )
with function _osm_relation_to_xml(osm_relation);