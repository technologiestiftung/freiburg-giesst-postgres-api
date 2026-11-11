-- Public bucket for harvester outputs (trees.csv, .mbtiles, weather).
-- Previously created in seed.sql only, so self-hosted/production setups missed it.
INSERT INTO storage.buckets (id, name, public)
	VALUES ('data_assets', 'data_assets', TRUE)
ON CONFLICT (id)
	DO UPDATE SET
		public = TRUE;

DROP POLICY IF EXISTS "Public Access" ON storage.objects;

CREATE POLICY "Public Access" ON storage.objects
	FOR SELECT
		USING (bucket_id = 'data_assets');
