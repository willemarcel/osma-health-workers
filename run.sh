#!/bin/bash

TilesURL="https://s3.amazonaws.com/mapbox/osm-qa-tiles-production/latest.country"
WORKDIR="data"
COUNTRY=$1
S3BUCKET=$2

# wget "$TilesURL/$COUNTRY.mbtiles.gz"
gunzip "$COUNTRY.mbtiles.gz"

# extract all the residential buildings
./workers/temporal.sh $COUNTRY $WORKDIR

# create a tileset of all residential buildings
tippecanoe -f -z 15 -Z 12 -l osm $WORKDIR/$COUNTRY/buildings.json -o $WORKDIR/$COUNTRY/buildings.mbtiles

# run attribute completeness validator and get stats
node ./workers/attribute-completeness.js $COUNTRY $WORKDIR

# filter all residential buildings and get edit receny stats
node ./workers/edit-recency.js $COUNTRY $WORKDIR

# run stats for duplicate buildings
node ./workers/duplicate-buildings.js $COUNTRY $WORKDIR > /dev/null

aws s3 sync $WORKDIR/$COUNTRY s3://$S3BUCKET/$WORKDIR/$COUNTRY