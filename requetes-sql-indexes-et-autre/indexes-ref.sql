CREATE INDEX planet_osm_polygon_ref_index ON planet_osm_polygon ("ref") WHERE ref IS NOT NULL;
