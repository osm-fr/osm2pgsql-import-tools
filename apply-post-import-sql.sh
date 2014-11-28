#!/bin/bash
#Please note that this scripts is called after the import. You don't need to run it manually unless you haven't imported with the import.sh script

. $(dirname $0)/config.sh

# running post import sql scripts (should this variable be unset, it shouldn't do anything, should an index allready exists, an armless error will be sent)
for sql in $operations_post_import ; do 
	cat $project_dir/requetes-sql-indexes-et-autre/$sql | psql $base_osm
done
