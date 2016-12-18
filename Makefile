all: explain reference json_explain

reindex:
	psql -f index.sql
	touch $@

import_types:
	psql -f types/tag.sql
	psql -f types/node.sql
	psql -f types/way.sql
	psql -f types/member.sql
	psql -f types/relation.sql

import_functions: burn_tags_into_nodes import_types
	cat functions/*.sql | psql

burn_tags_into_nodes: import_types
	#psql -f burn_tags_into_nodes.sql

db_ready: import_functions reindex

explain: db_ready
	rm explain_analyze_buffers.txt -rf
	cat fastmap.sql | sed s/--explain/explain/g | psql -q > explain_analyze_buffers.txt

explain_no_xml: db_ready
	rm explain_analyze_buffers.txt -rf
	cat fastmap.sql | sed s/--explain/explain/g | sed 's/: xml/: text/g' | psql -q > explain_analyze_buffers.txt

json_explain: db_ready
	rm explain.json -rf
	cat fastmap.sql | sed s/--jsonexplain/explain/g | psql -q > explain.json

json_explain_no_xml: db_ready
	rm explain.json -rf
	cat fastmap.sql | sed s/--jsonexplain/explain/g | sed 's/: xml/: text/g' | psql -q > explain.json

reference: db_ready
	rm reference.osm -rf
	time psql -q -f fastmap.sql > reference.osm

development_dump:
	pg_dump -c --if-exists -t current_nodes -t current_node_tags -t current_ways -t current_way_tags -t current_way_nodes -t current_relations -t current_relation_tags -t current_relation_members -t users -t changesets -Z 9 -f minsk.sqld.gz