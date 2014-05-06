CREATE INDEX planet_osm_polygon_boundary ON planet_osm_polygon USING gist (way) WITH (fillfactor=95) WHERE boundary IS NOT NULL;
CREATE INDEX planet_osm_polygon_way_local_auth ON planet_osm_polygon USING gist (way) WITH (fillfactor=95) WHERE tags ? 'local_authority:FR'::text;
CREATE INDEX planet_osm_polygon_way_ref_insee ON planet_osm_polygon USING gist (way) WITH (fillfactor=95) WHERE tags ? 'ref:INSEE'::text;
CREATE INDEX planet_osm_polygon_way_ref_nuts ON planet_osm_polygon USING gist (way) WITH (fillfactor=95) WHERE tags ? 'ref:NUTS'::text;

