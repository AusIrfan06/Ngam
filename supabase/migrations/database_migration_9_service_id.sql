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
