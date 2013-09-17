#!/bin/bash
# Script sur mesure pour nourrir la base postgres (schema osm2pgsql avec des diffs frais)

#la première étape consiste à lancer
#/home/ressource-for-osm/osmosis-0.32/bin/osmosis --rrii workingDirectory="."
#(cela ne sert a pas grand chose a part créer le fichier de configuration)
#puis editer le fichier configuration.txt et changer l'url et la durée du regroupement des diffs
#ensuite télécharger le fichier state.txt avec la date du full import (un peu avant pour ne rien perdre)
#le renomer en state.txt
#et roule avec ce script qu'on peut lancer toutes les minutes, 10 minutes ou comme on veut tant que 
#le fichier configuration.txt indique un interval plus grand que la fréquence de lancement sinon on ne rattrapera jamais
#le retard sur les diffs générés en amont

# le chevauchement de script est prévu par un fichier de lock
#set -e
DIFF_FILE="/dev/shm/diff.osc"
WORKDIR="/data/work/osm2pgsql"
#non utilisé sur osm7 :
EXPIRE_FILE=$WORKDIR"/expire.list"

#Si on veut avoir la charge du système pour déterminer si elle est en dessous de 2 ou non
LOAD=`uptime | grep -v "load average: [0-1]"`

#Quand il faut rattraper le temps et que le diff sera insérer peu importe la charge (a commenter pour que les updates ne se fasse que en periode "calme"
LOAD=""

CURDATE="`date +%F-%R`"
LOGFILE="$WORKDIR/replication-${CURDATE}.log"
ERRFILE="$WORKDIR/replication-${CURDATE}.err"

if [ ! -n "$LOAD" ] ; then

        #si le fichier de lock a plus de 10h c'est vraiment anormal (sans doute plantage, on refait), on le vire
        find ./lock -mmin  +600 -exec rm {} \; 2> /dev/null
        # si un processus tourne deja avec un lock, on ne fait rien non plus
        if [ -f lock ] ; then
	        exit
        fi
	touch lock

	# Osmosis a (avait?) tendance à planter et à bloquer le processus de mise à jour
	# le lock étant géré en amont par ce script, celui-ci ne sert à rien
	rm ./download.lock
	set -x		# prints command executed

	# Si le fichier diff est toujours là, c'est que osm2pgsql n'a pas pu l'importer, on ne télécharge pas de nouveau
	if ! test -e $DIFF_FILE ; then
		time ../osmosis-0.43.1/bin/osmosis --rri workingDirectory="." --simplify-change --write-xml-change $DIFF_FILE
	fi

	#Import du diff, avec création de la liste des tuiles à ré-générer
	time ../osm2pgsql/osm2pgsql -C 64 --number-processes=4 -G -a -s -S ./default.style --tag-transform-script style.lua -m -d osm $DIFF_FILE

	#import s'est bien passé a priori
	if [ $? == 0 ] ; then
		rm $DIFF_FILE
	fi
	
	set +x
	
	rm lock

	date

else
	echo "trop de charge"
fi

#exec 1>"$LOGFILE"
#exec 2>"$ERRFILE"
