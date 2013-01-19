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

-- Add indexes to speed special statistics tools -- sly
CREATE INDEX planet_osm_polygon_ref_index ON planet_osm_polygon ("ref") WHERE ref IS NOT NULL;
CREATE INDEX planet_osm_polygon_ref_insee_index ON planet_osm_polygon ("ref:INSEE") WHERE "ref:INSEE" IS NOT NULL; 
create index ref_sandre_index on planet_osm_line ("ref:sandre") WHERE "ref:sandre" IS NOT NULL;

/*A confirmer que celui-ci aide plutot que pénaliser : --sly*/
CREATE INDEX planet_osm_polygon_admin_level_index ON planet_osm_polygon ("admin_level") WHERE admin_level IS NOT NULL;


-- Si ça prend trop de place les buildings, on peut ne garder que ceux qui ont un tag "utile"
-- delete from planet_osm_polygon where building='yes' and name is null and amenity is null and man_made is null and tourism is null;    

-- Ajout d'une colonne pour les kms de voiries précalculés par commune, utile uniquement pour l'outil de F. Rodrigo -- sly
alter table planet_osm_polygon add column km_voirie float4;

GRANT SELECT ON planet_osm_point TO public;
GRANT SELECT ON planet_osm_ways TO public;
GRANT SELECT ON planet_osm_roads TO public;
GRANT SELECT ON planet_osm_polygon TO public;

