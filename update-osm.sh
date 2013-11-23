#!/bin/bash
# update script for updating a postgresql osm2pgsql scheam with diffs
# set -e

d=$(dirname $0)
. $d/config.sh

temporary_diff_file=$work_dir/diff.osc
file_with_import_timeings=$work_dir/diff-update-timing

current_date="`date +%F-%R`"
message_log_file=$work_dir/replication-${current_date}.log
error_log_file=$work_dir/replication-${current_date}.err

script_lock_pid_file=$work_dir/script_pid
osm2pgsql_lock_pid_file=$work_dir/osm2pgsql_pid
osmosis_lock_pid_file=$work_dir/osmosis_pid

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

if [ $verbosity == 0 ] ; then
  dev_null_redirection="2>/dev/null >/dev/null"
else
  dev_null_redirection=""
fi

#The pid file is older than 3 hours, we consider something went wrong (serveur reboot, task stucked)
#we kill everything that could still be live
#This is however suboptimal, if some other process got that pid (like after a server crash, we might kill some innoncent process)
if test -f $script_lock_pid_file ; then
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
rm $d/download.lock 2>/dev/null

if [ $verbosity == 1 ] ; then
  set -x # prints command executed
fi

# diff file still here ? we suppose it's the last one that should still be applied
if ! test -e $temporary_diff_file ; then
  time_spent start
  $osmosis --rri workingDirectory="." --simplify-change --write-xml-change $temporary_diff_file $dev_null_redirection &
  echo $! > $osmosis_lock_pid_file
  wait $!
  rm $osmosis_lock_pid_file
  time_spent stop osmosis
fi

#Veut-on une transformation par script lua ?
if [ -z "$lua_script_transform" ]; then
  lua="--tag-transform-script $lua_script_transform"
else
  lua=""
fi

if [ -z "$osm2pgsql_expire_option" ]; then
  expire_options="$osm2pgsql_expire_option -o $osm2pgsql_expire_tile_list"
else
  expire_options=""
fi

#Import du diff, avec création de la liste des tuiles à ré-générer
time_spent start
$osm2pgsql -a -s -S $style $lua -d $base_osm $osm2pgsql_options $expire_options $temporary_diff_file $dev_null_redirection &
echo $! > $osm2pgsql_lock_pid_file
wait $!
rm $osm2pgsql_lock_pid_file
time_spent stop osm2pgsql

if [ -z "$rendering_styles_tiles_to_expire" ]; then
  #when a rendering is used, expire the tiles for it
  time_spent start
  for sheet in $rendering_styles_tiles_to_expire ; do 
	  cat $osm2pgsql_expire_tile_list | render_expired --map=$sheet $render_expired_options $dev_null_redirection
  done	
  time_spent stop tile_expiry
  rm $osm2pgsql_expire_tile_list
fi

#looks like everything was well
if [ $? == 0 ] ; then
  rm $temporary_diff_file
  rm $script_lock_pid_file
fi

if [ $verbosity == 1 ] ; then
  set +x
fi

