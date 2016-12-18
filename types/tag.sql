drop type if exists osm_tag cascade;
create type osm_tag as (
    k text,
    v text
);

create function _osm_tag_to_xml(
    p_tag osm_tag
)
    returns xml parallel safe language sql as $$
select xmlelement(
    name tag,
    xmlattributes (
    (p_tag).k as k,
    (p_tag).v as v
    )
)
$$;

drop cast if exists ( osm_tag as xml );
create cast ( osm_tag as xml )
with function _osm_tag_to_xml(osm_tag);

create function _osm_tag_array_to_xml(
    p_tags osm_tag []
)
    returns xml parallel safe language sql as $$
select xmlagg(
    xmlelement(
        name tag,
        xmlattributes (
        p_tag.k as k,
        p_tag.v as v
        )
    ))
from unnest(p_tags) p_tag
$$;

drop cast if exists ( osm_tag [] as xml );
create cast ( osm_tag [] as xml )
with function _osm_tag_array_to_xml(osm_tag []);