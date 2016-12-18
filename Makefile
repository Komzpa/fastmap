all: explain reference

reindex:
	psql -f index.sql

import_types:
	psql -f types/tag.sql
	psql -f types/node.sql
	psql -f types/way.sql

import_functions: import_types
	cat functions/*.sql | psql

explain: import_functions reindex
	rm explain_analyze_buffers.txt -rf
	cat fastmap.sql | sed s/--explain/explain/g | psql -q > explain_analyze_buffers.txt

reference: import_functions reindex
	rm reference.osm -rf
	time psql -q -f fastmap.sql > reference.osm

development_dump:
	pg_dump -c --if-exists -t current_nodes -t current_node_tags -t current_ways -t current_way_tags -t current_way_nodes -t current_relations -t current_relation_tags -t current_relation_members -t users -t changesets -Z 9 -f minsk.sqld.gz