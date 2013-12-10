#This is where the import and update script are supposed to be found
project_dir=$(dirname $0)

#If those are in your path just set :
#osm2pgsql=osm2pgsql
#osmosis=osmosis
#the default is to suppose you find them in ../$tool/ relative to the root of where you put the import and update scipts

#binary paths
osm2pgsql=$project_dir/../osm2pgsql/osm2pgsql
osmosis=$project_dir/../osmosis/bin/osmosis

#database name to choose
base_osm=osm

#directory where temporary diff files will be stored, timeing for import, pid lock files and log files 
#/run/shm/ for a ram disk place is good if you don't care about timeings and logs after reboot
work_dir=/run/shm

#log errors and command output in the $work_dir (1 is yes, 0 is no)
with_log=0

#0 doesn't print anything out, 1 prints every commands that we run + output of commands
verbosity=0

#record timeings of osm2pgsql, osmosis and tile generation processing
with_timeings=1

#For osm2pgsql options (we could set the database name in it, but if an external script wants the database name, 
#it would be easier to keep it in a variable) 
#--tag-transform-script ./config/script.lua
common_osm2pgsql_options="--number-processes=4 -m -G -s -S $project_dir/config/default.style -d $base_osm"
diff_osm2pgsql_options="-a -C 64 $common_osm2pgsql_options"
import_osm2pgsql_options="--create --unlogged -C 3000 $common_osm2pgsql_options"


#Rendering related
#osm2pgsql expire list creation options (if empty no expiration list is built)
#osm2pgsql_expire_option="-e12-17"
osm2pgsql_expire_option=""
osm2pgsql_expire_tile_list=$work_dir/expire.list

#List of rendering style to run thru the render_expired commands
#Be sure that this scrpt as the filesystem rights to access tiles 
#separate style name by a space like "style1 style2"
rendering_styles_tiles_to_expire="2u openriverboatmap hot"
render_expired_options="--min-zoom=12 --touch-from=12 --max-zoom=20"

#Email to send end of initial import notice
end_of_import_email=""
