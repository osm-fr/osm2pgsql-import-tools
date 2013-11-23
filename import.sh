#!/bin/bash

d=$(dirname $0)
. $d/config.sh

if [ "a$1" == "a" ]; then
echo "usage : ./import.sh <.bz2 or .pbf file to import (can be an http/https/ftp url or local file) >"
echo "ex : ./import.sh /here/is/my/file.pbf"
echo "ex : ./import.sh http://site/file.pbf"
exit
fi

filename=$(basename "$1")
extension="${filename##*.}"

if [ $extension == "pbf" ] ; then
  parsing_mode="pbf"
  #FIXME I can't find a way to pass the | in the variable
  external_bunzip2="cat"
else
  external_bunzip2="bunzip2 -c"
  parsing_mode="libxml2"
fi

if [[ $1 =~ "http://" ]] || [[ $1 =~ "ftp://" ]] || [[ $1 =~ "https://" ]] ; then
  data_pipe="wget -q -O - $1 "
else
  data_pipe="cat $1 "
fi

echo $data_pipe $osm2pgsql $import_osm2pgsql_options -r $parsing_mode /dev/stdin

$data_pipe | $external_bunzip2 | $osm2pgsql $import_osm2pgsql_options -r $parsing_mode /dev/stdin


#Uncomment here and add your email to receive a mail when the import is done (yes, for planet imports it can take days !)
#echo "fin import $1" | mail -s "import $1 fini" your@email.org -- -f your@email.org
