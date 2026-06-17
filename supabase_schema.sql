-- =========================================================================================
-- Ngam App — Supabase Database Schema
-- Run this in the Supabase SQL Editor (SQL Editor -> New Query)
-- =========================================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. USERS TABLE
-- This stores the extended profile for users who signed up via Supabase Auth.
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(50) NOT NULL,
  role VARCHAR(50) NOT NULL, -- 'pemesan' or 'runner'
  is_verified_runner BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. GIGS TABLE
-- This stores the task/errand broadcasts.
CREATE TABLE IF NOT EXISTS public.gigs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  gig_worker_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(50) NOT NULL,
  bounty_amount DECIMAL(10, 2) NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'OPEN', -- 'OPEN', 'LOCKED', 'IN-PROGRESS', 'COMPLETED', 'CANCELLED'
  location VARCHAR(255) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. STATUS LOGS TABLE
-- This stores the history of status changes for a gig.
CREATE TABLE IF NOT EXISTS public.status_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  gig_id UUID NOT NULL REFERENCES public.gigs(id) ON DELETE CASCADE,
  status VARCHAR(50) NOT NULL,
  changed_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. REVIEWS TABLE
-- This stores the ratings/comments given by customers to runners.
CREATE TABLE IF NOT EXISTS public.reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  gig_id UUID NOT NULL REFERENCES public.gigs(id) ON DELETE CASCADE,
  reviewer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =========================================================================================
-- Set up Row Level Security (RLS) - Required for public API access
-- =========================================================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gigs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.status_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- 5. RUNNER VERIFICATIONS TABLE
-- Stores KYC verification data for runners
CREATE TABLE IF NOT EXISTS public.runner_verifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  full_name VARCHAR(255) NOT NULL,
  ic_number VARCHAR(50) NOT NULL,
  vehicle_type VARCHAR(50) NOT NULL,
  plate_number VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Disable RLS constraints (allow all operations for this project since auth rules are handled app-side)
-- Note: In a real production app, you would want strict RLS rules.
DROP POLICY IF EXISTS "Allow public select on users" ON public.users;
CREATE POLICY "Allow public select on users" ON public.users FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow public insert on users" ON public.users;
CREATE POLICY "Allow public insert on users" ON public.users FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public update on users" ON public.users;
CREATE POLICY "Allow public update on users" ON public.users FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Allow public all on gigs" ON public.gigs;
CREATE POLICY "Allow public all on gigs" ON public.gigs FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public all on status_logs" ON public.status_logs;
CREATE POLICY "Allow public all on status_logs" ON public.status_logs FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public all on reviews" ON public.reviews;
CREATE POLICY "Allow public all on reviews" ON public.reviews FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public all on verifications" ON public.runner_verifications;
CREATE POLICY "Allow public all on verifications" ON public.runner_verifications FOR ALL USING (true) WITH CHECK (true);

-- Realtime for the gigs table is configured safely at the end of the file

-- =========================================================================================
-- Chat System (Conversations and Messages)
-- =========================================================================================

-- 5. CONVERSATIONS TABLE
CREATE TABLE IF NOT EXISTS public.conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user1_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  user2_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  gig_id UUID REFERENCES public.gigs(id) ON DELETE SET NULL,
  last_message TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user1_id, user2_id)
);

-- 6. MESSAGES TABLE
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for Chat System
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Disable RLS constraints for now (allowing all for simplicity in development)
DROP POLICY IF EXISTS "Allow public all on conversations" ON public.conversations;
CREATE POLICY "Allow public all on conversations" ON public.conversations FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public all on messages" ON public.messages;
CREATE POLICY "Allow public all on messages" ON public.messages FOR ALL USING (true) WITH CHECK (true);

-- Enable Realtime for conversations and messages (PostgreSQL syntax safe wrap)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'conversations'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
  END IF;
  
  -- Also wrap gigs for realtime safety
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'gigs'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.gigs;
  END IF;
END
$$;


