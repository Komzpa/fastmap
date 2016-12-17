# fastmap
Fast OSM API /map call implementation in pure SQL.

## why

This /map call takes 22 seconds to complete on osm.org. [Current cgimap implementation](https://github.com/zerebubuth/openstreetmap-cgimap/blob/ff414930a7db284f00dfb91bd3e000cb126e5d69/src/backend/apidb/readonly_pgsql_selection.cpp) needs ~2 network round trips between database and application, effectively limiting API speed to ~2000 objects per second.

Details in Operations ticket: https://github.com/openstreetmap/operations/issues/135

## development cycle quick start

```bash
# set up your Postgres environment
export PGUSER=gis PGDATABASE=gis

# import data to your postgres
zcat minsk.sqld.gz | psql

# change something
vim fastmap.sql

# re-export reference data and explain
make

# observe changes you've made
git diff
```

## getting complete database schema

We believe there is postgres database `gis`, user `gis`, accepting trust connections on localhost.

```bash
# grab software
sudo apt install osmosis curl wget unzip
# import schema
curl https://raw.githubusercontent.com/openstreetmap/openstreetmap-website/master/db/structure.sql | psql
# get latest osmosis wit non-broken pbf support
wget http://bretth.dev.openstreetmap.org/osmosis-build/osmosis-latest.zip
unzip osmosis-latest.zip
# grab osm dump of Belarus
wget http://data.gis-lab.info/osm_dump/dump/latest/BY.osm.pbf
# import
bin/osmosis --read-pbf file="BY.osm.pbf" --log-progress --write-apidb database="gis" user="gis" host="localhost" validateSchemaVersion=no
```