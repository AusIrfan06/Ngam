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
