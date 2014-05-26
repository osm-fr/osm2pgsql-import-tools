#!/bin/bash
project_dir=$(dirname $0)

#If those are in your path just set :
#osm2pgsql=osm2pgsql
#osmosis=osmosis
#if you want relative path use $project_dir instead like $project_dir/../path-to-binary or $project_dir/path-to-binary
#$project_dir beeing the directory this config.sh file is

#binary paths
osm2pgsql=$project_dir/../osm2pgsql/osm2pgsql
osmosis=$project_dir/../osmosis-0.43.1/bin/osmosis

#database name to choose
base_osm=osm

#directory where temporary diff files will be stored, timeing for import, pid lock files and log files 
#/run/shm/ for a ram disk place is good if you don't care about timeings and logs after reboot
work_dir=/run/shm/osm2pgsql-import


#log errors and command output in the $work_dir (1 is yes, 0 is no)
with_log=0

#0 doesn't print anything out, 1 prints every commands that we run + output of commands
verbosity=1

#record timeings of osm2pgsql, osmosis and tile generation processing
with_timeings=1

#For osm2pgsql options (database name is not hardcoded here because some scripts needs it as a variable, so we just make use of it here)
#--tag-transform-script $project_dir/script.lua (pensez à faire des chemin absolu ou utilisez $project_dir sinon, ça foire quand c'est pas lancé du dossier en cours)
common_osm2pgsql_options=" -k -m -G -s -S $project_dir/osm2pgsql-choosen.style -d $base_osm --flat-nodes /ssd/osm2pgsql/flat-nodes.raw --keep-coastlines --tag-transform-script $project_dir/config/activate-relation-type-waterway.lua"
diff_osm2pgsql_options="--number-processes=8 -a -C 64 $common_osm2pgsql_options"
import_osm2pgsql_options="--create -C 16000 --number-processes=8 $common_osm2pgsql_options --tablespace-main-data ssd --tablespace-main-index ssd --tablespace-slim-data ssd --tablespace-slim-index ssd "

#post import sql scripts in directory "requetes-sql-indexes-et-autre" to run, separated by spaces. (index-planet_osm_ways-a-reindexer.sql at least is recommended to rebuild a failing index)
operations_post_import="index-planet_osm_ways-a-reindexer.sql"

#Rendering related
#osm2pgsql expire list creation options (if empty no expiration list is built)
osm2pgsql_expire_option="-e12-17"

osm2pgsql_expire_tile_list=$work_dir/expire.list

#List of rendering style to run thru the render_expired commands
#Be sure that this script as the filesystem rights to access tiles 
#if empty, no expiration will occure, you'll have to do it with the expiry tile files in an other way
rendering_styles_tiles_to_expire=$(grep "^\[" /etc/renderd.conf | egrep -v "(renderd|mapnik)" | cut -d"[" -f2 | cut -d"]" -f1)
render_expired_options="--min-zoom=12 --touch-from=12 --max-zoom=20"

#You can use this to execute the render_expired with another user like "sudo -u www-data"
render_expired_prefix="sudo -u www-data"

#Email to send end of initial import notice
end_of_import_email="alertes@letuffe.org"
