CREATE INDEX planet_osm_polygon_admin_level_index ON planet_osm_polygon ("admin_level") WHERE admin_level IS NOT NULL;
