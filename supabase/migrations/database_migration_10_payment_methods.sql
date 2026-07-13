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
