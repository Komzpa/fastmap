create index if not exists current_nodes_point_longitude_latitude_spgist_visible
    on current_nodes using spgist (point(longitude :: float / 1e7 :: float, latitude :: float / 1e7 :: float))
    where visible;
create index if not exists current_nodes_id_visible
    on current_nodes (id)
    where visible;
create index if not exists current_ways_id_visible
    on current_ways (id)
    where visible;
create index if not exists current_relations_id_visible
    on current_relations (id)
    where visible;
create index on users (id)
    where data_public;
analyse;