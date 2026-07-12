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
