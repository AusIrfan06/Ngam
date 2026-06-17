-- =========================================================================================
-- Ngam App — Avatar Setup
-- Run this in your Supabase SQL Editor to enable Avatar Uploads!
-- =========================================================================================

-- 1. Add the avatar_url column to your public.users table safely
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS avatar_url VARCHAR;

-- 2. Create the Storage Bucket for Avatars
INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- 3. Set up Storage Policies (RLS) for the 'avatars' bucket

-- Allow public read access to all avatars
CREATE POLICY "Avatar Public View"
ON storage.objects FOR SELECT
USING ( bucket_id = 'avatars' );

-- Allow authenticated users to upload an avatar to their own folder (e.g. user_id/avatar.jpg)
CREATE POLICY "Avatar User Upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' AND 
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to update/overwrite their own avatar
CREATE POLICY "Avatar User Update"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars' AND 
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to delete their own avatar
CREATE POLICY "Avatar User Delete"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars' AND 
  (storage.foldername(name))[1] = auth.uid()::text
);
