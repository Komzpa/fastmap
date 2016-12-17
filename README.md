# fastmap
Fast OSM API /map call implementation in pure SQL

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