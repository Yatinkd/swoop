-- =============================================================================
-- plan-covers bucket — Storage RLS policies
-- Run this entire script in: Supabase Dashboard → SQL Editor → New query
--
-- Fixes: StorageException "new row violates row-level security policy" (403)
-- Upload path used by the app: {user_id}/{timestamp}.{ext}
-- =============================================================================

-- 1) Bucket (public so getPublicUrl works without signed URLs)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'plan-covers',
  'plan-covers',
  true,
  5242880, -- 5 MB
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 2) Remove old policies if re-running (safe to run multiple times)
DROP POLICY IF EXISTS "Users can upload plan covers" ON storage.objects;
DROP POLICY IF EXISTS "Public read plan covers" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated read plan covers" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own plan covers" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own plan covers" ON storage.objects;

-- Helper: first path segment must match the signed-in user's UUID
-- e.g. name = '550e8400-e29b-41d4-a716-446655440000/1710000000000.jpg'

-- 3) INSERT — authenticated users upload only into their own folder
CREATE POLICY "Users can upload plan covers"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'plan-covers'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- 4) SELECT — anyone can view (public bucket + public read)
CREATE POLICY "Public read plan covers"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'plan-covers');

-- 5) SELECT — authenticated users can also read (some clients use this role)
CREATE POLICY "Authenticated read plan covers"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'plan-covers');

-- 6) UPDATE — users can replace files in their own folder (e.g. upsert)
CREATE POLICY "Users can update own plan covers"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'plan-covers'
  AND auth.uid()::text = (storage.foldername(name))[1]
)
WITH CHECK (
  bucket_id = 'plan-covers'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- 7) DELETE — users can remove their own uploads
CREATE POLICY "Users can delete own plan covers"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'plan-covers'
  AND auth.uid()::text = (storage.foldername(name))[1]
);
