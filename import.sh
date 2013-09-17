#!/bin/bash

if [ "a$1" == "a" ]; then
echo "usage : ./import.sh <.bz2 or .pbf file to import>"
echo "(Paths are related to the script's path, do not call it like /data/bidule/import.sh)"
exit
fi


cat ./pre-post-import/clean.sql | psql osm

filename=$(basename "$1")
extension="${filename##*.}"

time ../osm2pgsql/osm2pgsql --create --number-processes=4 -C 3000 -s -S ./default.style --tag-transform-script style.lua --tag-transform-script style.lua -G -m --unlogged -d osm $1

cat ./pre-post-import/after_create.sql | psql osm

#Here if you want to receive an email when the import is done
echo "fin import $1" | mail -s "import $1 fini" your@email.org -- -f your@email.org
