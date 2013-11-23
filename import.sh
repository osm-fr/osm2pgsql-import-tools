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

if [ $1 =~ "http://" ] || $1 =~ "ftp://" ] || $1 =~ "https://" ] ; then
  wget_pipe="wget -q -O - $1 |"
else
  wget_pipe="cat $1 |"
fi


time $wget_pipe $osm2pgsql --create -s -S $style $lua -d $base_osm $osm2pgsql_options $expire_options $temporary_diff_file


#Uncomment here and add your email to receive a mail when the import is done (yes, for planet imports it can take days !)
#echo "fin import $1" | mail -s "import $1 fini" your@email.org -- -f your@email.org
