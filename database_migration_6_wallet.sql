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
