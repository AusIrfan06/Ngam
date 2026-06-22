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
