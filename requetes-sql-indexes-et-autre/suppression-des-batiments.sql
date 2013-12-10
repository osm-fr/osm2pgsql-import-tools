-- Si ça prend trop de place les buildings, on peut ne garder que ceux qui ont un tag "utile"
delete from planet_osm_polygon where building='yes' and name is null and amenity is null and man_made is null and tourism is null;    

