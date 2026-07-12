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
