-- Ajout d'une colonne pour les kms de voiries précalculés par commune, utile uniquement pour l'outil de F. Rodrigo -- sly
alter table planet_osm_polygon add column km_voirie float4;
