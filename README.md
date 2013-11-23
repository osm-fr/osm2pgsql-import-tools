Ce dossier est maintenau par git, toute bidouille à la main pourrait être écrasée par une future synchro.
Paramétrez plutôt les deux fichiers de configuration !

osm2pgsql-import-tools
======================

1 scripts pour importer une base osm au schéma osm2pgsql
et 1 pour la maintenir à jour avec des diffs.

je tente au mieux de gérer les problèmes qui peuvent survenir, d'avoir le plus possible en paramètre, avoir un suivi de perf

Installation
============

* Voir http://wiki.openstreetmap.org/wiki/Osm2pgsql qui détaille comment compiler et comment fonctionne osm2pgsql (avec support lua et pbf).

* Il vous faudra aussi osmosis pour télécharger les diffs

* copier ./config/config-sample.sh vers ./config.sh et adaptez les chemins & les options (ou prenez un fichier déjà existant d'exemple)

* copier ./config/configuration-sample.txt vers ./configuration.txt et adaptez le chemin des diffs (ou prenez un fichier déjà existant d'exemple)

options :
---------
* If you want some more indexes and simplified geometries (usefull for layers.openstreetmap.fr and suivi communes) :
``
. ./config.sh ; cat ./pre-post-import/after_create.sql | psql $base_osm
``





La suite n'est plus vraiment à jour, merci de bien lire les scripts, c'est là que vous aurrez la dernière info (et proposer de mettre à jour cet aide !)

Cette mini doc explique comment importer la base osm2pgsql afin qu'elle
puisse servir à layers.openstreetmap.fr, à suivi.openstreetmap.fr et à
d'autres outils qui s'y connectent.
Note 09/11/2012 : j'ai tout indiqué de tête, ça va donc foirer ou oublier
quelque chose, n'hésitez pas à compléter
Questions ? sylvain at letuffe p org

= import de la base =
Créer un compte shell et le même dans postgresql (habituellement osm2pgsql)
créer un schéma osm2pgsql et le rendre par défaut pour l'utilisateur
osm2pgsql

Se connecter avec le compte shell osm2pgsql

@ Import des données osm
cd /import-base-osm
usage : ./import.sh <osm.bz2 file to import>
(le pbf n'est pas prévu, a vous de le convertir avec osmconvert par exemple)

le fichier default.style défini les objets a importer selon leurs tags
présents dans ce fichier

@ traitement à lancer ensuite
./pre-post-import/after_create.sql : la liste des post-traitements à faire
après import (qui est appelé par le script import.sh)


@ autres données à importer
cd ./sql-dumps
on importe tous les sql qui sont là :
gunzip -c truc.sql.gz | psql osm2pgsql

@ gestion des roles d'accès
se connecter en shell postgresql
cd ./gestion-des-access
(voir fichier roles-a-creer.txt)
for x in `cat roles.txt` ; do u=`echo $x | cut -f1 -d\;` ; p=`echo $x | cut -f2 -d\;` ; ./creation-roles.sh $u $p ; done

= import des minutes diffs pour maintenir à jour =

configuration.txt : C'est l'endroit ou on indique la provenance des diffs,
et le nombre qu'il faut en télécharger à la fois

On met ça dans le cron :
# Quand la base est en retard : mettre toutes les minutes, en mode croisière toutes les ~10 minutes
*/10 * * * * (sleep 15; cd /data/project/osm2pgsql/import-base-osm ; ./update-osm.sh >>/data/work/osm2pgsql/log/replication-$(date +'\%Y-\%m-\%d').log 2>&1)
*/10 * * * * sleep 15; cd /data/project/osm2pgsql/import-base-osm 

= traitements réguliers =

on met ça dans le cron :
# Ce traitement est pas mal long, 1 fois par semaine suffit

0 3 * * 0 cd /data/project/osm2pgsql/mise-a-jour-regulieres ; ./mise-a-jour.sh
