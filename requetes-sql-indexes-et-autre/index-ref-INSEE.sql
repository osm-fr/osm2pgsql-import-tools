CREATE INDEX planet_osm_polygon_way_ref_insee ON planet_osm_polygon USING gist (way) WITH (fillfactor=95) WHERE tags ? 'ref:INSEE'::text;

