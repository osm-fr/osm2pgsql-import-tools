#!/bin/bash

d=$(dirname $0)
. $d/config.sh

if [ "a$1" == "a" ]; then
echo "usage : ./import.sh <.bz2 or .pbf file to import>"
echo "(Paths are related to the script's path, do not call it like /data/bidule/import.sh)"
exit
fi


filename=$(basename "$1")
extension="${filename##*.}"

time $osm2pgsql --create --number-processes=4 -C 3000 -s -S $style --tag-transform-script style.lua -G -m --unlogged -d $base_osm $1

cat $d/pre-post-import/after_create.sql | psql $base_osm

#Uncomment here and add your email to receive a mail when the import is done (yes, for planet imports it can take days !)
#echo "fin import $1" | mail -s "import $1 fini" your@email.org -- -f your@email.org
