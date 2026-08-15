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
  runner_latitude DOUBLE PRECISION,
  runner_longitude DOUBLE PRECISION,
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

-- 8. PAYMENT METHODS TABLE
CREATE TABLE IF NOT EXISTS public.payment_methods (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL, -- 'card', 'bank', 'duitnow_qr'
  is_primary BOOLEAN DEFAULT FALSE,
  color_index INTEGER DEFAULT 0,
  holder_name VARCHAR(255),
  name VARCHAR(255),
  details VARCHAR(255),
  expiry VARCHAR(10),
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
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;

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

-- ==========================================
-- 8. PAYMENT METHODS
-- ==========================================
CREATE POLICY "Users can view their own payment methods" 
ON public.payment_methods FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own payment methods" 
ON public.payment_methods FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own payment methods" 
ON public.payment_methods FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own payment methods" 
ON public.payment_methods FOR DELETE USING (auth.uid() = user_id);


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


-- 1. Add the new JSONB column to the conversations table
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS task_last_messages JSONB DEFAULT '{}'::jsonb;

-- 2. Create the RPC function to atomically update the task_last_messages and global last_message
CREATE OR REPLACE FUNCTION update_conversation_task_message(
  p_conversation_id UUID,
  p_sender_id UUID,
  p_message_content TEXT,
  p_gig_id UUID
) RETURNS void AS $$
BEGIN
  UPDATE conversations
  SET 
    -- Safely merge the new message into the JSON object
    task_last_messages = COALESCE(task_last_messages, '{}'::jsonb) || jsonb_build_object(p_gig_id::text, p_message_content),
    last_message = p_message_content,
    last_message_sender_id = p_sender_id,
    last_message_is_read = false,
    updated_at = NOW()
  WHERE id = p_conversation_id;
END;
$$ LANGUAGE plpgsql;

-- 1. Add the new JSONB column to the conversations table
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS task_unread_counts JSONB DEFAULT '{}'::jsonb;

-- 2. Update the RPC function to increment task_unread_counts
CREATE OR REPLACE FUNCTION update_conversation_task_message(
  p_conversation_id UUID,
  p_sender_id UUID,
  p_message_content TEXT,
  p_gig_id UUID
) RETURNS void AS $$
DECLARE
  current_counts JSONB;
  current_count INT;
BEGIN
  -- Fetch the current task_unread_counts
  SELECT COALESCE(task_unread_counts, '{}'::jsonb) INTO current_counts FROM conversations WHERE id = p_conversation_id;
  
  -- Extract the current count for this specific gig_id, defaulting to 0
  current_count := COALESCE((current_counts->>p_gig_id::text)::INT, 0);

  UPDATE conversations
  SET 
    -- Safely merge the new message into the JSON object
    task_last_messages = COALESCE(task_last_messages, '{}'::jsonb) || jsonb_build_object(p_gig_id::text, p_message_content),
    -- Safely increment the unread count for this specific gig_id
    task_unread_counts = current_counts || jsonb_build_object(p_gig_id::text, current_count + 1),
    last_message = p_message_content,
    last_message_sender_id = p_sender_id,
    last_message_is_read = false,
    updated_at = NOW()
  WHERE id = p_conversation_id;
END;
$$ LANGUAGE plpgsql;

-- 1. Update the RPC function to reset task_unread_counts when the sender changes
CREATE OR REPLACE FUNCTION update_conversation_task_message(
  p_conversation_id UUID,
  p_sender_id UUID,
  p_message_content TEXT,
  p_gig_id UUID
) RETURNS void AS $$
DECLARE
  current_counts JSONB;
  current_count INT;
  prev_sender_id UUID;
BEGIN
  -- Fetch the current task_unread_counts and last_message_sender_id
  SELECT 
    COALESCE(task_unread_counts, '{}'::jsonb),
    last_message_sender_id
  INTO 
    current_counts,
    prev_sender_id
  FROM conversations 
  WHERE id = p_conversation_id;
  
  -- If the sender changed, it means the new sender has seen previous messages
  -- or at least, the unread direction has flipped. So we reset the counts.
  IF prev_sender_id IS NOT NULL AND prev_sender_id != p_sender_id THEN
    current_counts := '{}'::jsonb;
    current_count := 0;
  ELSE
    -- Extract the current count for this specific gig_id, defaulting to 0
    current_count := COALESCE((current_counts->>p_gig_id::text)::INT, 0);
  END IF;

  UPDATE conversations
  SET 
    -- Safely merge the new message into the JSON object
    task_last_messages = COALESCE(task_last_messages, '{}'::jsonb) || jsonb_build_object(p_gig_id::text, p_message_content),
    -- Safely increment the unread count for this specific gig_id
    task_unread_counts = current_counts || jsonb_build_object(p_gig_id::text, current_count + 1),
    last_message = p_message_content,
    last_message_sender_id = p_sender_id,
    last_message_is_read = false,
    updated_at = NOW()
  WHERE id = p_conversation_id;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- NGAM APP: ROW LEVEL SECURITY (RLS) MIGRATION
-- ==========================================

-- 1. Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gigs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.status_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.runner_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- 2. Drop old dangerous policies
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
-- 3. USERS
-- ==========================================
DROP POLICY IF EXISTS "Users can be viewed by anyone" ON public.users;
CREATE POLICY "Users can be viewed by anyone" 
ON public.users FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
CREATE POLICY "Users can insert their own profile" 
ON public.users FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
CREATE POLICY "Users can update their own profile" 
ON public.users FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can delete their own profile" ON public.users;
CREATE POLICY "Users can delete their own profile" 
ON public.users FOR DELETE USING (auth.uid() = id);

-- ==========================================
-- 4. GIGS
-- ==========================================
DROP POLICY IF EXISTS "Gigs can be viewed by anyone" ON public.gigs;
CREATE POLICY "Gigs can be viewed by anyone" 
ON public.gigs FOR SELECT USING (true);

DROP POLICY IF EXISTS "Customers can insert their own gigs" ON public.gigs;
CREATE POLICY "Customers can insert their own gigs" 
ON public.gigs FOR INSERT WITH CHECK (auth.uid() = customer_id);

DROP POLICY IF EXISTS "Customers and Assigned Runners can update gigs" ON public.gigs;
CREATE POLICY "Customers and Assigned Runners can update gigs" 
ON public.gigs FOR UPDATE 
USING (
    auth.uid() = customer_id OR 
    auth.uid() = gig_worker_id OR 
    (status = 'OPEN' AND gig_worker_id IS NULL) -- Allow runner to accept open gig
);

DROP POLICY IF EXISTS "Customers can delete their own gigs" ON public.gigs;
CREATE POLICY "Customers can delete their own gigs" 
ON public.gigs FOR DELETE USING (auth.uid() = customer_id);

-- ==========================================
-- 5. CONVERSATIONS & MESSAGES
-- ==========================================
DROP POLICY IF EXISTS "Users can view their conversations" ON public.conversations;
CREATE POLICY "Users can view their conversations" 
ON public.conversations FOR SELECT 
USING (auth.uid() = user1_id OR auth.uid() = user2_id);

DROP POLICY IF EXISTS "Users can insert their conversations" ON public.conversations;
CREATE POLICY "Users can insert their conversations" 
ON public.conversations FOR INSERT 
WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

DROP POLICY IF EXISTS "Users can update their conversations" ON public.conversations;
CREATE POLICY "Users can update their conversations" 
ON public.conversations FOR UPDATE 
USING (auth.uid() = user1_id OR auth.uid() = user2_id);

DROP POLICY IF EXISTS "Users can view messages in their conversations" ON public.messages;
CREATE POLICY "Users can view messages in their conversations" 
ON public.messages FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM public.conversations c 
        WHERE c.id = messages.conversation_id 
        AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid())
    )
);

DROP POLICY IF EXISTS "Users can insert their own messages" ON public.messages;
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

-- 1. Add balance to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS balance DECIMAL(10, 2) DEFAULT 0.00;

-- 2. Create transactions table
CREATE TABLE IF NOT EXISTS public.transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL, -- 'topup', 'payment', 'refund', 'earning'
  amount DECIMAL(10, 2) NOT NULL,
  gig_id UUID REFERENCES public.gigs(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- Users can view their own transactions
CREATE POLICY "Users can view their own transactions" 
ON public.transactions FOR SELECT 
USING (auth.uid() = user_id);

-- 3. Create RPC Function to post gig with payment securely
CREATE OR REPLACE FUNCTION public.create_gig_with_payment(
  p_id UUID,
  p_customer_id UUID,
  p_gig_worker_id UUID,
  p_title VARCHAR,
  p_description TEXT,
  p_category VARCHAR,
  p_bounty_amount DECIMAL,
  p_status VARCHAR,
  p_location VARCHAR,
  p_latitude DOUBLE PRECISION,
  p_longitude DOUBLE PRECISION
) RETURNS json AS $$
DECLARE
  current_balance DECIMAL;
BEGIN
  -- 1. Check user balance (Row-level lock for safety)
  SELECT balance INTO current_balance FROM public.users WHERE id = p_customer_id FOR UPDATE;
  
  IF current_balance < p_bounty_amount THEN
    RAISE EXCEPTION 'Insufficient balance. You have RM%, but RM% is required.', current_balance, p_bounty_amount;
  END IF;

  -- 2. Deduct balance
  UPDATE public.users SET balance = balance - p_bounty_amount WHERE id = p_customer_id;

  -- 3. Record transaction
  INSERT INTO public.transactions (user_id, type, amount, gig_id)
  VALUES (p_customer_id, 'payment', -p_bounty_amount, p_id);

  -- 4. Insert Gig
  INSERT INTO public.gigs (
    id, customer_id, gig_worker_id, title, description, category, 
    bounty_amount, status, location, latitude, longitude
  ) VALUES (
    p_id, p_customer_id, p_gig_worker_id, p_title, p_description, p_category, 
    p_bounty_amount, p_status, p_location, p_latitude, p_longitude
  );

  -- 5. Insert Status Log
  INSERT INTO public.status_logs (gig_id, status) VALUES (p_id, p_status);

  -- Return success
  RETURN json_build_object('success', true, 'new_balance', current_balance - p_bounty_amount);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. RPC for Top Up
CREATE OR REPLACE FUNCTION public.top_up_wallet(
  p_user_id UUID,
  p_amount DECIMAL
) RETURNS json AS $$
DECLARE
  new_balance DECIMAL;
BEGIN
  -- 1. Add balance
  UPDATE public.users SET balance = balance + p_amount WHERE id = p_user_id RETURNING balance INTO new_balance;

  -- 2. Record transaction
  INSERT INTO public.transactions (user_id, type, amount)
  VALUES (p_user_id, 'topup', p_amount);

  RETURN json_build_object('success', true, 'new_balance', new_balance);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. RPC for Task Completion (Earning for Runner)
CREATE OR REPLACE FUNCTION public.complete_gig_and_pay(
  p_gig_id UUID,
  p_runner_id UUID
) RETURNS json AS $$
DECLARE
  gig_record RECORD;
BEGIN
  -- Lock gig record
  SELECT * INTO gig_record FROM public.gigs WHERE id = p_gig_id FOR UPDATE;
  
  IF gig_record.status = 'COMPLETED' THEN
    RAISE EXCEPTION 'Gig is already completed';
  END IF;

  -- Verify runner
  IF gig_record.gig_worker_id != p_runner_id THEN
    RAISE EXCEPTION 'Only assigned runner can complete this gig';
  END IF;

  -- Update gig status
  UPDATE public.gigs SET status = 'COMPLETED' WHERE id = p_gig_id;
  INSERT INTO public.status_logs (gig_id, status) VALUES (p_gig_id, 'COMPLETED');

  -- Pay the runner
  UPDATE public.users SET balance = balance + gig_record.bounty_amount WHERE id = p_runner_id;
  
  -- Record transaction
  INSERT INTO public.transactions (user_id, type, amount, gig_id)
  VALUES (p_runner_id, 'earning', gig_record.bounty_amount, p_gig_id);

  RETURN json_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. RPC for Cancellation (Refund for Customer)
CREATE OR REPLACE FUNCTION public.cancel_gig_and_refund(
  p_gig_id UUID,
  p_user_id UUID
) RETURNS json AS $$
DECLARE
  gig_record RECORD;
BEGIN
  -- Lock gig record
  SELECT * INTO gig_record FROM public.gigs WHERE id = p_gig_id FOR UPDATE;
  
  IF gig_record.status = 'CANCELLED' THEN
    RAISE EXCEPTION 'Gig is already cancelled';
  END IF;

  IF gig_record.status = 'COMPLETED' THEN
    RAISE EXCEPTION 'Completed gig cannot be cancelled';
  END IF;

  -- Update gig status
  UPDATE public.gigs SET status = 'CANCELLED', gig_worker_id = NULL WHERE id = p_gig_id;
  INSERT INTO public.status_logs (gig_id, status) VALUES (p_gig_id, 'CANCELLED');

  -- Refund the customer
  UPDATE public.users SET balance = balance + gig_record.bounty_amount WHERE id = gig_record.customer_id;
  
  -- Record transaction
  INSERT INTO public.transactions (user_id, type, amount, gig_id)
  VALUES (gig_record.customer_id, 'refund', gig_record.bounty_amount, p_gig_id);

  RETURN json_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 1. RPC for Withdrawal
CREATE OR REPLACE FUNCTION public.withdraw_wallet(
  p_user_id UUID,
  p_amount DECIMAL
) RETURNS json AS $$
DECLARE
  current_balance DECIMAL;
  new_balance DECIMAL;
BEGIN
  -- 1. Check user balance (Row-level lock for safety)
  SELECT balance INTO current_balance FROM public.users WHERE id = p_user_id FOR UPDATE;
  
  IF current_balance < p_amount THEN
    RAISE EXCEPTION 'Insufficient balance. You have RM%, but RM% is required.', current_balance, p_amount;
  END IF;

  -- 2. Deduct balance
  UPDATE public.users SET balance = balance - p_amount WHERE id = p_user_id RETURNING balance INTO new_balance;

  -- 3. Record transaction
  INSERT INTO public.transactions (user_id, type, amount)
  VALUES (p_user_id, 'withdrawal', -p_amount);

  RETURN json_build_object('success', true, 'new_balance', new_balance);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fix for foreign key constraint violation in create_gig_with_payment RPC
-- The previous version inserted into transactions before gigs, which caused a FK violation.

CREATE OR REPLACE FUNCTION public.create_gig_with_payment(
  p_id UUID,
  p_customer_id UUID,
  p_gig_worker_id UUID,
  p_title VARCHAR,
  p_description TEXT,
  p_category VARCHAR,
  p_bounty_amount DECIMAL,
  p_status VARCHAR,
  p_location VARCHAR,
  p_latitude DOUBLE PRECISION,
  p_longitude DOUBLE PRECISION
) RETURNS json AS $$
DECLARE
  current_balance DECIMAL;
BEGIN
  -- 1. Check user balance (Row-level lock for safety)
  SELECT balance INTO current_balance FROM public.users WHERE id = p_customer_id FOR UPDATE;
  
  IF current_balance < p_bounty_amount THEN
    RAISE EXCEPTION 'Insufficient balance. You have RM%, but RM% is required.', current_balance, p_bounty_amount;
  END IF;

  -- 2. Deduct balance
  UPDATE public.users SET balance = balance - p_bounty_amount WHERE id = p_customer_id;

  -- 3. Insert Gig FIRST to satisfy Foreign Key constraint
  INSERT INTO public.gigs (
    id, customer_id, gig_worker_id, title, description, category, 
    bounty_amount, status, location, latitude, longitude
  ) VALUES (
    p_id, p_customer_id, p_gig_worker_id, p_title, p_description, p_category, 
    p_bounty_amount, p_status, p_location, p_latitude, p_longitude
  );

  -- 4. Record transaction (now that gig_id exists)
  INSERT INTO public.transactions (user_id, type, amount, gig_id)
  VALUES (p_customer_id, 'payment', -p_bounty_amount, p_id);

  -- 5. Insert Status Log
  INSERT INTO public.status_logs (gig_id, status) VALUES (p_id, p_status);

  -- Return success
  RETURN json_build_object('success', true, 'new_balance', current_balance - p_bounty_amount);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 1. Add service_id column to gigs table
ALTER TABLE public.gigs ADD COLUMN IF NOT EXISTS service_id UUID REFERENCES public.gigs(id) ON DELETE CASCADE;

-- 2. Add service_id to create_gig_with_payment RPC to link bookings to their parent service
CREATE OR REPLACE FUNCTION public.create_gig_with_payment(
  p_id UUID,
  p_customer_id UUID,
  p_gig_worker_id UUID,
  p_title VARCHAR,
  p_description TEXT,
  p_category VARCHAR,
  p_bounty_amount DECIMAL,
  p_status VARCHAR,
  p_location VARCHAR,
  p_latitude DOUBLE PRECISION,
  p_longitude DOUBLE PRECISION,
  p_service_id UUID DEFAULT NULL
) RETURNS json AS $$
DECLARE
  current_balance DECIMAL;
BEGIN
  -- 1. Check user balance (Row-level lock for safety)
  SELECT balance INTO current_balance FROM public.users WHERE id = p_customer_id FOR UPDATE;
  
  IF current_balance < p_bounty_amount THEN
    RAISE EXCEPTION 'Insufficient balance. You have RM%, but RM% is required.', current_balance, p_bounty_amount;
  END IF;

  -- 2. Deduct balance
  UPDATE public.users SET balance = balance - p_bounty_amount WHERE id = p_customer_id;

  -- 3. Insert Gig FIRST to satisfy Foreign Key constraint
  INSERT INTO public.gigs (
    id, customer_id, gig_worker_id, title, description, category, 
    bounty_amount, status, location, latitude, longitude, service_id
  ) VALUES (
    p_id, p_customer_id, p_gig_worker_id, p_title, p_description, p_category, 
    p_bounty_amount, p_status, p_location, p_latitude, p_longitude, p_service_id
  );

  -- 4. Record transaction (now that gig_id exists)
  INSERT INTO public.transactions (user_id, type, amount, gig_id)
  VALUES (p_customer_id, 'payment', -p_bounty_amount, p_id);

  -- 5. Insert Status Log
  INSERT INTO public.status_logs (gig_id, status) VALUES (p_id, p_status);

  -- Return success
  RETURN json_build_object('success', true, 'new_balance', current_balance - p_bounty_amount);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 1. Create payment_methods table
CREATE TABLE IF NOT EXISTS public.payment_methods (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL, -- 'card', 'bank', 'duitnow_qr'
  is_primary BOOLEAN DEFAULT FALSE,
  color_index INTEGER DEFAULT 0,
  holder_name VARCHAR(255),
  name VARCHAR(255),
  details VARCHAR(255),
  expiry VARCHAR(10),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Enable Row Level Security (RLS)
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;

-- 3. RLS Policies
-- Users can view their own payment methods
CREATE POLICY "Users can view their own payment methods" 
ON public.payment_methods FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own payment methods
CREATE POLICY "Users can insert their own payment methods" 
ON public.payment_methods FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own payment methods
CREATE POLICY "Users can update their own payment methods" 
ON public.payment_methods FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own payment methods
CREATE POLICY "Users can delete their own payment methods" 
ON public.payment_methods FOR DELETE USING (auth.uid() = user_id);

