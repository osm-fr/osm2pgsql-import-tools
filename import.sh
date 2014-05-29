#!/bin/bash

. $(dirname $0)/config.sh

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

# running post import sql scripts (should this variable be unset, it shouldn't do anything)
for sql in $operations_post_import ; do 
	cat $project_dir/requetes-sql-indexes-et-autre/$sql | psql $base_osm
done

if [ ! -z $end_of_import_email ] ; then
  echo "End of $1 import with osm2pgsql on `hostname`" | mail -s "This email does'nt tell you that this import went well, it tells you it ended ;-)" $end_of_import_email -- -f $end_of_import_email
fi
