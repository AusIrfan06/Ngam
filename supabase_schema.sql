-- =========================================================================================
-- Ngam App — Supabase Database Schema
-- Run this in the Supabase SQL Editor (SQL Editor -> New Query)
-- =========================================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. USERS TABLE
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(50) NOT NULL,
  role VARCHAR(50) NOT NULL,
  is_verified_runner BOOLEAN DEFAULT FALSE,
  bio TEXT,
  gender VARCHAR(20),
  birth_date DATE,
  address TEXT,
  avatar_url VARCHAR,
  fcm_token TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. GIGS TABLE
CREATE TABLE IF NOT EXISTS public.gigs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  gig_worker_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(50) NOT NULL,
  bounty_amount DECIMAL(10, 2) NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'OPEN', 
  location VARCHAR(255) NOT NULL,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. STATUS LOGS TABLE
CREATE TABLE IF NOT EXISTS public.status_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  gig_id UUID NOT NULL REFERENCES public.gigs(id) ON DELETE CASCADE,
  status VARCHAR(50) NOT NULL,
  changed_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. REVIEWS TABLE
CREATE TABLE IF NOT EXISTS public.reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  gig_id UUID NOT NULL REFERENCES public.gigs(id) ON DELETE CASCADE,
  reviewer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. RUNNER VERIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS public.runner_verifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  full_name VARCHAR(255) NOT NULL,
  ic_number VARCHAR(50) NOT NULL,
  vehicle_type VARCHAR(50) NOT NULL,
  plate_number VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 6. CONVERSATIONS TABLE
CREATE TABLE IF NOT EXISTS public.conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user1_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  user2_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  gig_id UUID REFERENCES public.gigs(id) ON DELETE SET NULL,
  last_message TEXT,
  last_message_sender_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  last_message_is_read BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 7. MESSAGES TABLE
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);


-- =========================================================================================
-- Set up Row Level Security (RLS) & Policies
-- =========================================================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gigs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.status_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.runner_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Safe Policy Deletion (Remove old dangerous policies)
DO $$
BEGIN
    DROP POLICY IF EXISTS "Allow public select on users" ON public.users;
    DROP POLICY IF EXISTS "Allow public insert on users" ON public.users;
    DROP POLICY IF EXISTS "Allow public update on users" ON public.users;
    DROP POLICY IF EXISTS "Allow public all on gigs" ON public.gigs;
    DROP POLICY IF EXISTS "Allow public all on conversations" ON public.conversations;
    DROP POLICY IF EXISTS "Allow public all on messages" ON public.messages;
    DROP POLICY IF EXISTS "Allow public all on verifications" ON public.runner_verifications;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- ==========================================
-- 1. USERS
-- ==========================================
-- Anyone can view user profiles
CREATE POLICY "Users can be viewed by anyone" 
ON public.users FOR SELECT USING (true);

-- Users can only insert their own profile
CREATE POLICY "Users can insert their own profile" 
ON public.users FOR INSERT WITH CHECK (auth.uid() = id);

-- Users can only update their own profile
CREATE POLICY "Users can update their own profile" 
ON public.users FOR UPDATE USING (auth.uid() = id);

-- Users can only delete their own profile
CREATE POLICY "Users can delete their own profile" 
ON public.users FOR DELETE USING (auth.uid() = id);

-- ==========================================
-- 2. GIGS
-- ==========================================
-- Anyone can view gigs
CREATE POLICY "Gigs can be viewed by anyone" 
ON public.gigs FOR SELECT USING (true);

-- Customers can insert gigs
CREATE POLICY "Customers can insert their own gigs" 
ON public.gigs FOR INSERT WITH CHECK (auth.uid() = customer_id);

-- Customers can update their own gigs, Runners can update gigs they are assigned to
CREATE POLICY "Customers and Assigned Runners can update gigs" 
ON public.gigs FOR UPDATE 
USING (
    auth.uid() = customer_id OR 
    auth.uid() = gig_worker_id OR 
    (status = 'OPEN' AND gig_worker_id IS NULL) -- Allow runner to accept open gig
);

-- Only Customers can delete their own gigs
CREATE POLICY "Customers can delete their own gigs" 
ON public.gigs FOR DELETE USING (auth.uid() = customer_id);

-- ==========================================
-- 3. STATUS LOGS
-- ==========================================
CREATE POLICY "Status logs viewable by anyone" 
ON public.status_logs FOR SELECT USING (true);

CREATE POLICY "Status logs insertable by anyone" 
ON public.status_logs FOR INSERT WITH CHECK (true); 
-- In a real prod environment, restrict this to customer or runner of the gig.

-- ==========================================
-- 4. REVIEWS
-- ==========================================
CREATE POLICY "Reviews viewable by anyone" 
ON public.reviews FOR SELECT USING (true);

CREATE POLICY "Users can insert their own reviews" 
ON public.reviews FOR INSERT WITH CHECK (auth.uid() = reviewer_id);

CREATE POLICY "Users can edit their own reviews" 
ON public.reviews FOR UPDATE USING (auth.uid() = reviewer_id);

CREATE POLICY "Users can delete their own reviews" 
ON public.reviews FOR DELETE USING (auth.uid() = reviewer_id);

-- ==========================================
-- 5. RUNNER VERIFICATIONS
-- ==========================================
-- Only the runner themselves can read their verification info
CREATE POLICY "Runners can view their own verification" 
ON public.runner_verifications FOR SELECT USING (auth.uid() = user_id);

-- Runners can only insert their own info
CREATE POLICY "Runners can insert their own verification" 
ON public.runner_verifications FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Runners can update their own info
CREATE POLICY "Runners can update their own verification" 
ON public.runner_verifications FOR UPDATE USING (auth.uid() = user_id);

-- ==========================================
-- 6. CONVERSATIONS
-- ==========================================
-- Users can only see conversations they are part of
CREATE POLICY "Users can view their conversations" 
ON public.conversations FOR SELECT 
USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Users can only create conversations involving themselves
CREATE POLICY "Users can insert their conversations" 
ON public.conversations FOR INSERT 
WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Users can only update their conversations
CREATE POLICY "Users can update their conversations" 
ON public.conversations FOR UPDATE 
USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- ==========================================
-- 7. MESSAGES
-- ==========================================
-- Users can view messages in their conversations
CREATE POLICY "Users can view messages in their conversations" 
ON public.messages FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM public.conversations c 
        WHERE c.id = messages.conversation_id 
        AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid())
    )
);

-- Users can insert messages if they are the sender
CREATE POLICY "Users can insert their own messages" 
ON public.messages FOR INSERT 
WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (
        SELECT 1 FROM public.conversations c 
        WHERE c.id = messages.conversation_id 
        AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid())
    )
);


-- Enable Realtime for conversations, messages, and gigs safely
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'conversations') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'messages') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'gigs') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.gigs;
  END IF;
END
$$;

-- =========================================================================================
-- Avatar Storage Setup
-- =========================================================================================

-- Create the Storage Bucket for Avatars
INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Set up Storage Policies (RLS) for the 'avatars' bucket

-- Allow public read access to all avatars
DO $$
BEGIN
    DROP POLICY IF EXISTS "Avatar Public View" ON storage.objects;
    CREATE POLICY "Avatar Public View" ON storage.objects FOR SELECT USING ( bucket_id = 'avatars' );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Allow authenticated users to upload an avatar
DO $$
BEGIN
    DROP POLICY IF EXISTS "Avatar User Upload" ON storage.objects;
    CREATE POLICY "Avatar User Upload" ON storage.objects FOR INSERT TO authenticated WITH CHECK (
        bucket_id = 'avatars' AND 
        (storage.foldername(name))[1] = auth.uid()::text
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

