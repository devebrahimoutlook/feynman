-- Migration: `002-auth-user-management`
-- Purpose: Apply RLS to user_profile and create `avatars` storage bucket.

-- 1. Enforce RLS on user_profile
ALTER TABLE user_profile ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own profile" ON user_profile
  FOR SELECT TO authenticated
  USING (auth.uid()::text = id);

CREATE POLICY "Users update own profile" ON user_profile
  FOR UPDATE TO authenticated
  USING (auth.uid()::text = id)
  WITH CHECK (auth.uid()::text = id);

CREATE POLICY "Users insert own profile" ON user_profile
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid()::text = id);

-- Note: No DELETE policy; account deletion requires Edge Function with service_role.

-- 2. Create `avatars` storage bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  TRUE,
  5242880, -- 5 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 3. Storage RLS Policies
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
  FOR SELECT TO public
  USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'avatars' AND
    auth.uid()::text = (string_to_array(name, '/'))[1]
  );

CREATE POLICY "Users can update their own avatar" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (string_to_array(name, '/'))[1]
  );

CREATE POLICY "Users can delete their own avatar" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (string_to_array(name, '/'))[1]
  );
