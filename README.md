Ce dossier est maintenau par git, toute bidouille à la main pourrait être écrasée par une future synchro.
Paramétrez plutôt les deux fichiers de configuration !

osm2pgsql-import-tools
======================

1 scripts pour importer une base osm au schéma osm2pgsql
et 1 pour la maintenir à jour avec des diffs.

je tente au mieux de gérer les problèmes qui peuvent survenir, d'avoir le plus possible en paramètre, avoir un suivi de perf et d'éviter de trifouiller les scripts
en n'ayant à intervenir que dans les fichiers du dossier "config"

Installation
============

* Voir http://wiki.openstreetmap.org/wiki/Osm2pgsql qui détaille comment compiler et comment fonctionne osm2pgsql (avec support lua et pbf).

* Il vous faudra aussi osmosis pour télécharger les diffs (voir wiki aussi)

* copier ./config/config-sample.sh vers ./config.sh et adaptez les chemins & les options (ou prenez un fichier déjà existant d'exemple ou faite un lien symbolique de ./config.sh vers ceux déjà prêt dans ./config/ selon )

* pareil pour ./config/configuration-sample.txt qui devient ./configuration.txt

* pareil enfin pour un style d'osm2pgsql que vous pouvez copier de ./config/*.style vers osm2pgsql-choosen.style 
(vous pouvez aussi laisser la config par défaut qui va chercher le ./config/default.style, mais si quelqu'un met à jour le style par défaut, ça pourrait vous poser problème)

Lancement
=========

Import initial
--------------
Depuis une URL en "streaming" :
./import.sh http://la-bas/un-fichier.osm.bz2 (ou pbf)
ou depuis un ficher local préalablement téléchargé :
./import.sh /truc/fichier.osm.bz2 (ou pbf)

Maintenir à jour
----------------
Trouver le fichier state.txt qui soit quelques minutes avant la date de génération du fichier que vous avez utilisé et placer le 
dans le dossier racine (au même niveau que ce fichier README.md)
Si vous utilisez le fichier planet, un truc comme ça :
wget -q -O - http://planet.osm.org/planet/planet-latest.osm.bz2 | bunzip2 | head -n 10 | grep timestamp

vous sort le timestamp du dernier fichier bz2 (qui est le même que celui du pbf, prenez alors fichier state.txt quelque part là dedans : http://planet.osm.org/replication/minute/ 
qui soit antérieur à cette date)

on met ça dans le cron :
# Quand la base est en retard : mettre toutes les minutes, en mode croisière toutes les ~10 minutes
*/10 * * * * (sleep 15; /data/project/osm2pgsql/import-base-osm/update-osm.sh >>/data/work/osm2pgsql/log/replication-$(date +'\%Y-\%m-\%d').log 2>&1)
ou en plus simple (sans garder les logs):
*/10 * * * * sleep 15; cd /data/project/osm2pgsql/import-base-osm/update-osm.sh 

Note pour debug : dans le config.sh vous pouvez activer une sortie verbeuse pour avoir plus d'info que seulement les grosses erreurs


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


