#!/bin/bash

. $(dirname $0)/config.sh

if [ "a$1" == "a" ]; then
echo "usage : ./import.sh <.pbf file to import>"
echo "ex : ./import.sh /here/is/my/file.pbf"
exit
fi

parsing_mode="pbf"

echo $osm2pgsql $import_osm2pgsql_options -r $parsing_mode $1

$osm2pgsql $import_osm2pgsql_options -r $parsing_mode $1

# running post import sql scripts (will do nothing if no sql scripts configured in config.sh)
$project_dir/apply-post-import-sql.sh

if [ ! -z $end_of_import_email ] ; then
  echo "End of $1 import with osm2pgsql on `hostname`" | mail -s "This email does'nt tell you that this import went well, it tells you it ended ;-)" $end_of_import_email -- -f $end_of_import_email
fi
