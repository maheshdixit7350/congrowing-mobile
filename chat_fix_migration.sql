-- Chat Feature Fix Migration
-- Adds last_seen to users table and is_read to messages table

-- 1. Add last_seen column to users for "Last seen X ago" display
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS last_seen TIMESTAMPTZ;

-- 2. Add is_read column to messages for read receipts
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT FALSE NOT NULL;
