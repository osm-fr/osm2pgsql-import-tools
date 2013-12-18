-- utile à l'outils qui gère la comparaison au sandre
create index hstore_tags_ref_sandre on planet_osm_line using hash ((tags->'ref:sandre'));