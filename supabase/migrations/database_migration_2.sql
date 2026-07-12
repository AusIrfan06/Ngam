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
