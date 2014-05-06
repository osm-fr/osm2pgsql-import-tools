CREATE INDEX planet_osm_polygon_geohash ON planet_osm_polygon USING btree (st_geohash(st_transform(way, 4326))) with (fillfactor=95);
CREATE INDEX planet_osm_line_geohash ON planet_osm_line USING btree (st_geohash(st_transform(way, 4326))) with (fillfactor=95);
CREATE INDEX planet_osm_point_geohash ON planet_osm_point USING btree (st_geohash(st_transform(way, 4326))) with (fillfactor=95);

