#This is where the import and update script are supposed to be found
project_dir=$(dirname $0)

#If those are in your path just set :
#osm2pgsql=osm2pgsql
#osmosis=osmosis
#if you want relative path use $project_dir instead like $project_dir/../path-to-binary or $project_dir/path-to-binary
#$project_dir beeing the directory this config.sh file is

#binary paths
osm2pgsql=$project_dir/../osm2pgsql/osm2pgsql
osmosis=$project_dir/../osmosis/bin/osmosis

#database name to choose, in a variable to be able to adapt other scripts than the import & update ones
base_osm=osm

#directory where temporary diff files will be stored, timeing for import, pid lock files and log files 
#/run/shm for a ram disk place is good if you don't care about timeings and logs after reboot
work_dir=/run/shm

#0 doesn't print anything out, 1 prints every commands that we run + output of commands
verbosity=0

#record timeings of osm2pgsql, osmosis and tile generation processing
with_timeings=1

#For osm2pgsql options (we could set the database name in it, but if an external script (and there is one !) wants the database name, 
#it is easier to keep it in a variable) 
#need some lua script ? add this : --tag-transform-script $project_dir/script.lua (no relative path, use $project_dir to refer to current dir)

common_osm2pgsql_options="--number-processes=4 -m -G -s -S $project_dir/config/default.style -d $base_osm"
diff_osm2pgsql_options="-a -C 64 $common_osm2pgsql_options"
import_osm2pgsql_options="--create -C 3000 $common_osm2pgsql_options"

#post import sql scripts in directory "requetes-sql-indexes-et-autre" to run, separated by spaces. (index-planet_osm_ways-a-reindexer.sql at least is recommended to rebuild a failing index)
operations_post_import="index-planet_osm_ways-a-reindexer.sql"


#Rendering related
#osm2pgsql expire list creation options (if empty no expiration list is built)
#osm2pgsql_expire_option="-e12-17"
osm2pgsql_expire_option=""
osm2pgsql_expire_tile_list=$work_dir/expire.list

#List of rendering style to run thru the render_expired commands
#Be sure that this script has the filesystem rights to access tiles 
#separate style name by a space like "style1 style2"
#if empty, no expiration will occure, you'll have to do it with the expiry tile files in an other way

#With this hack it will automatically expire styles from the /etc/renderd.conf file
#rendering_styles_tiles_to_expire="$(grep "^\[" /etc/renderd.conf | egrep -v "(renderd|mapnik)" | cut -d"[" -f2 | cut -d"]" -f1)"
rendering_styles_tiles_to_expire=""

render_expired_options="--min-zoom=12 --touch-from=12 --max-zoom=20"

#You can use this to execute the render_expired with another user like "sudo -u www-data"
render_expired_prefix=""

#Email to send end of initial import notice
end_of_import_email=""
