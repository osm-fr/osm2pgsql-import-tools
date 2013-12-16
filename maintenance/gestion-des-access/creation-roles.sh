#!/bin/bash
if [ "a$1" == "a" ] || [ "a$2" == "a" ] ; then
	echo "usage : creation-roles.sh <role> <mot de passe>"
	echo "ATTENTION : a lancer avec un compte administrateur de la base (en général postgres)"
exit
fi
d=$(dirname $0)
. $d/../../config.sh

user=$1
password=$2
base=$base_osm

createuser $user
psql $base -c "GRANT USAGE ON SCHEMA osm2pgsql to \"$user\""
psql $base -c "GRANT USAGE ON SCHEMA public to \"$user\""
psql $base -c "GRANT SELECT ON geometry_columns to \"$user\""
psql $base -c "GRANT SELECT ON spatial_ref_sys to \"$user\""
psql $base -c "CREATE SCHEMA \"$user\""
psql $base -c "ALTER SCHEMA \"$user\" OWNER TO \"$user\""
psql $base -c "ALTER USER \"$user\" SET search_path TO \"$user\",osm2pgsql,public"
psql $base -c "ALTER USER \"$user\" WITH PASSWORD '$password';"
