--This geometry column holds a simplified version of the full geometry for administrative boundaries, it greatly accelerate 
--some computations -- sly
ALTER TABLE planet_osm_polygon drop column simplified_way;
ALTER TABLE planet_osm_polygon add column simplified_way GEOMETRY;


--This function will be triggered after every geometry boundary construction
--Patching osm2pgsql might probably a better way to do this, but well, it works ;-) -- sly
CREATE OR REPLACE FUNCTION simplify() RETURNS trigger
AS $simplify$
BEGIN
IF NEW.boundary IS NOT NULL THEN
UPDATE "planet_osm_polygon" SET simplified_way=ST_SimplifyPreserveTopology(way,600) WHERE osm_id = NEW.osm_id;

RAISE NOTICE 'simplification polygone boundary';
RETURN NEW;
END IF;
RETURN NEW;
END;
$simplify$ LANGUAGE plpgsql;

DROP TRIGGER simplify ON planet_osm_polygon;
CREATE TRIGGER simplify AFTER INSERT ON planet_osm_polygon
     FOR EACH ROW EXECUTE PROCEDURE simplify();
     
     
--Create the simplified geometries -- sly
UPDATE "planet_osm_polygon" SET simplified_way=ST_SimplifyPreserveTopology(way,600) WHERE boundary is not NULL;

-- Add an index to the simplified column
CREATE INDEX planet_osm_polygon_simplified_way ON planet_osm_polygon USING gist (simplified_way);
