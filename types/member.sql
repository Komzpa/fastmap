drop type if exists osm_member cascade;
create type osm_member as (
    type text,
    ref  bigint,
    role text
);

create function _osm_member_to_xml(
    p_member osm_member
)
    returns xml stable parallel safe language sql as $$
select xmlelement(
    name member,
    xmlattributes (
    (p_member).type as type,
    (p_member).ref as ref,
    (p_member).role as role
)
)
$$;

drop cast if exists ( osm_member as xml );
create cast ( osm_member as xml )
with function _osm_member_to_xml(osm_member);

create function _osm_member_array_to_xml(
    p_members osm_member []
)
    returns xml stable parallel safe language sql as $$
select xmlagg(
    xmlelement(
        name member,
        xmlattributes (
        p_member.type as type,
        p_member.ref as ref,
        p_member.role as role
    )
))
from unnest(p_members) p_member
$$;

drop cast if exists ( osm_member [] as xml );
create cast ( osm_member [] as xml )
with function _osm_member_array_to_xml(osm_member []);