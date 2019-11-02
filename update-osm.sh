#!/bin/bash
# update script for updating a postgresql osm2pgsql scheam with diffs
# set -e

. $(dirname $0)/config.sh

if [ "$max_load" != "" ] ; then
  # check load average, if too high, exit
  if [ "$(grep '^[0-9]*' -o /proc/loadavg)" -ge "$max_load" ]; then
    exit
  fi
fi

# FIXME : I'm sure there is a better way to use parameters with bash scripts, but I'm lazy to search for it
if [ "$1" == "-v" ] || [ "$2" == "-v" ] ; then # To force verbosity for manual run without need to mess up with config file
  verbosity=1
fi

if [ $verbosity == 1 ] ; then
  dev_null_redirection=""
  set -x # prints command executed   
else
  dev_null_redirection="> /dev/null"
fi

temporary_diff_file=$work_dir/diff.osc
file_with_import_timeings=$work_dir/diff-update-timing

current_date="`date +%F-%R`"
message_log_file=$work_dir/replication-${current_date}.log
error_log_file=$work_dir/replication-${current_date}.err

# FIXME : pid file should go into a more appropriate zone such as /run/ on debian, but I don't really want to hard code it for debian only ;-)
script_lock_pid_file=$work_dir/script.pid
osm2pgsql_lock_pid_file=$work_dir/osm2pgsql.pid
osmosis_lock_pid_file=$work_dir/osmosis.pid

#create work_dir
mkdir $work_dir 2>/dev/null

function time_spent {
if [ $with_timeings == 0 ] ; then
  return;
fi
if [ $1 == "start" ] ; then
        deb=`date +%s`
else
	date=$(date "+%Y-%m-%d %H:%M:%S")
        echo "$date,$2,$((`date +%s`-$deb))" >> $file_with_import_timeings
fi
}


#The pid file is older than 300 minutes (maybe make this a parameter ?), we consider something went wrong (serveur reboot, task stucked)
#we kill everything that could still be live
#This is however suboptimal, if some other process got that pid (like after a server crash, we might kill some innoncent process from the user running this script so : don't run it as root !
if [ -f $script_lock_pid_file ]; then
  if test `find $script_lock_pid_file -mmin +300` ; then
    for pid_file in $osmosis_lock_pid_file $osm2pgsql_lock_pid_file $script_lock_pid_file; do
      kill -9 `cat $pid_file` 2>/dev/null
      rm $pid_file 2>/dev/null
    done
  else # The previous running of that script is still running, exit
    exit
  fi
fi
#record the shell script's pid
echo $$ > $script_lock_pid_file

# Osmosis creates it's own lock duplicate of our own pid/lock system
# I happens once in a while that osmosis get stucked or crashes, removing that lock
# for running it again is what I came to as a lazy solution
rm $project_dir/download.lock 2>/dev/null

# We found an old state.txt.old file, if it is here, then something went wront, restart from that state file
if [ -e $project_dir/state.txt.old ] ; then
	cp $project_dir/state.txt.old $project_dir/state.txt
fi

#Save current state file to state.txt.old
cp $project_dir/state.txt $project_dir/state.txt.old
time_spent start
eval $osmosis --rri workingDirectory="$project_dir" --buffer-change --simplify-change --write-xml-change $temporary_diff_file $dev_null_redirection &
echo $! > $osmosis_lock_pid_file
wait $!
rm $osmosis_lock_pid_file
time_spent stop osmosis


if [ ! -s $temporary_diff_file ] ; then
  rm $script_lock_pid_file
  echo "Osmosis failed to download and create a non null diff. Exiting now." 1>&2
  exit
fi

if [ ! -z "$osm2pgsql_expire_option" ]; then
  expire_options="$osm2pgsql_expire_option -o $osm2pgsql_expire_tile_list"
else
  expire_options=""
fi

#Import du diff, avec création de la liste des tuiles à ré-générer
time_spent start
eval $osm2pgsql $diff_osm2pgsql_options $expire_options $temporary_diff_file $dev_null_redirection &
echo $! > $osm2pgsql_lock_pid_file
wait $!
osm2pgsql_exit_code=$?

rm $osm2pgsql_lock_pid_file
time_spent stop osm2pgsql

if [ ! -z "$rendering_styles_tiles_to_expire" ]; then
  #when a rendering is used, expire the tiles for it
  time_spent start
  for sheet in $rendering_styles_tiles_to_expire ; do
	cat $osm2pgsql_expire_tile_list | eval $render_expired_prefix render_expired --map=$sheet $render_expired_options $dev_null_redirection
  done
  time_spent stop tile_expiry
  rm $osm2pgsql_expire_tile_list
fi

if [ ! -z "$expire_dir" ]; then
  # gzip expiry list
  time_spent start
  d=$(date --utc +%FT%TZ)
  mv $osm2pgsql_expire_tile_list $osm2pgsql_expire_tile_list-$d
  mkdir $expire_dir
  gzip $osm2pgsql_expire_tile_list-$d && mv $osm2pgsql_expire_tile_list-$d.gz $expire_dir
  time_spent stop tile_exp_gzip
fi

#looks like everything was well
if [ $osm2pgsql_exit_code == 0 ] ; then
  rm $temporary_diff_file
  rm $project_dir/state.txt.old
else
  echo "osm2pgsql failed at importing diffs, more information if you enable verbosity." 1>&2
fi

rm $script_lock_pid_file

if [ $verbosity == 1 ] ; then
  set +x
fi

