-- Run in Supabase SQL Editor to enable plan cover photo uploads

INSERT INTO storage.buckets (id, name, public)
VALUES ('plan-covers', 'plan-covers', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Authenticated users can upload to their own folder
CREATE POLICY "Users can upload plan covers"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'plan-covers'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Anyone can view plan cover images
CREATE POLICY "Public read plan covers"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'plan-covers');

-- Users can update/delete their own uploads
CREATE POLICY "Users can update own plan covers"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'plan-covers'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Users can delete own plan covers"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'plan-covers'
  AND (storage.foldername(name))[1] = auth.uid()::text
);
