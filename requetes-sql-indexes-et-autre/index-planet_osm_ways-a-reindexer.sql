-- cet index foire après chaque importation intiale, je pige pas pourquoi... mais le réindexer permet de gérer de where pending sans seqential scan
reindex index planet_osm_ways_idx;

