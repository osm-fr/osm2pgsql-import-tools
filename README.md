Those are shell scripts for importing and maintaining up to date an osm2pgsql schema of a postgresql database 
+ tools around that 
+ SQL requests for custom indexes 
+ management of renderd tile expiry

osm2pgsql-import-tools
======================

Quick overview :
./config.sh --> common config file (write your own with ./config/* as models or examples)
./import.sh ---> to import from a .osm .osm.bz2 .pbf file or URL
./update-osm.sh ---> to import diff updates (see http://wiki.openstreetmap.org/wiki/Minutely_Mapnik )

side tools :
./render_list.sh --> to command renderd to render some zoom levels
./maintenance/time-spent-by-all-steps.sh --> benchmarks on time spent by different steps or update process (need activation)
./maintenance/from-temporary-tables-during-import-to-production.sh --> simple script to drop and move production tables after import to reduce downtime
./maintenance/gestion-des-access/creation-roles.sh --> postgres roles creation with read only access to osm2pgsql tables

Installation
============

* Read http://wiki.openstreetmap.org/wiki/Osm2pgsql to compile osm2pgsql

* http://wiki.openstreetmap.org/wiki/Osmosis for diff download and grouping

* Copy ./config/config-sample.sh to ./config.sh and adapt (or use some adapted to extract or full planet)

* Copy ./config/configuration-sample.txt to ./configuration.txt

* Copy some osm2pgsql style file from ./config/*.style to osm2pgsql-choosen.style (optionnal if you want the default one, then edit config.sh acordingly)

Running
=========

Initial import
--------------

From a URL ( "streaming" mode) :
./import.sh http://la-bas/un-fichier.osm.bz2 (or pbf)
or from a local file :
./import.sh /truc/fichier.osm.bz2 (or pbf)

Update your database
--------------------
Download the state.txt file a few minutes earlier than the osm file you imported and put it aside from "update-osm.sh" script

Tweak : If you are importing from planet file at planet.osm.org, this command : 
wget -q -O - http://planet.osm.org/planet/planet-latest.osm.bz2 | bunzip2 | head -n 10 | grep timestamp
should get you the timestamp of the file. If you are using the pbf file, timestamp is exactly the same, then get the state.txt here : http://planet.osm.org/replication/minute/ 
with a date just before.

Then put in your contrab a line like :
*/10 * * * * $PATH/update-osm.sh > some_log_file 2>&1

Tweak for debuging : in config.sh you can activate a more verbose output for more information
OR
run "./update-osm.sh -v" to force verbose mode



Older french documentation :

CHECKLISTE pour une ré-importation sur un système en prod :
- restarter postgresql en interdisant toutes les connexions sauf postgres et osm2pgsql en socket unix (donc local) -> c'est pour éviter que des requêtes aient lieu quand les données sont là, mais pas encore les indexes
(si munin : - empêcher munin de calculer la taille des schémas qui, pour une raison qui m'échappe, semble ne pas aboutir : à vérifier fichier /etc/munin/postgres_schema_size_osm)
- couper les update faites par osm2pgsql dans le cron
- lancer l'import dans un screen
- prépare le state.txt correspondent au fichier de l'import


La suite n'est plus vraiment à jour, merci de bien lire les scripts, c'est là que vous aurrez la dernière info (et proposer de mettre à jour cet aide !)

Cette mini doc explique comment importer la base osm2pgsql afin qu'elle
puisse servir à layers.openstreetmap.fr, à suivi.openstreetmap.fr et à
d'autres outils qui s'y connectent.
Note 09/11/2012 : j'ai tout indiqué de tête, ça va donc foirer ou oublier
quelque chose, n'hésitez pas à compléter
Questions ? sylvain at letuffe p org

= import de la base =
Créer une base osm
Créer un compte shell et le même dans postgresql (habituellement osm2pgsql)
créer un schéma osm2pgsql et le rendre par défaut pour l'utilisateur
osm2pgsql

Se connecter avec le compte shell osm2pgsql


@ gestion des roles d'accès
se connecter en shell postgresql
cd maintenance/gestion-des-access/
(voir fichier roles-a-creer.txt)
for x in `cat roles.txt` ; do u=`echo $x | cut -f1 -d\;` ; p=`echo $x | cut -f2 -d\;` ; ./creation-roles.sh $u $p ; done

la liste des roles.txt peut être récupérer sur le wiki d'osm-fr : http://docs.openstreetmap.fr


= import des minutes diffs pour maintenir à jour =

configuration.txt : C'est l'endroit ou on indique la provenance des diffs,
et le nombre qu'il faut en télécharger à la fois


