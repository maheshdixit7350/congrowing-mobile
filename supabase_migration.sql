-- ConGrowing Supabase Database Setup Migration
-- This script initializes all 11 tables, RLS policies, storage buckets, and automated counters triggers.

-- Enable UUID extension if not enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. CLEANUP (Drop tables if they exist to allow clean reinstall)
-- ─────────────────────────────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS on_follows_change ON public.follows;
DROP FUNCTION IF EXISTS public.handle_follows_change();
DROP TRIGGER IF EXISTS on_thoughts_change ON public.thoughts;
DROP FUNCTION IF EXISTS public.handle_thoughts_change();

DROP TABLE IF EXISTS public.callee_candidates CASCADE;
DROP TABLE IF EXISTS public.caller_candidates CASCADE;
DROP TABLE IF EXISTS public.rooms CASCADE;
DROP TABLE IF EXISTS public.daily_missions CASCADE;
DROP TABLE IF EXISTS public.reviews CASCADE;
DROP TABLE IF EXISTS public.thought_comments CASCADE;
DROP TABLE IF EXISTS public.thoughts CASCADE;
DROP TABLE IF EXISTS public.messages CASCADE;
DROP TABLE IF EXISTS public.chat_rooms CASCADE;
DROP TABLE IF EXISTS public.follows CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. CREATE TABLES
-- ─────────────────────────────────────────────────────────────────────────────

-- Users Table
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    username TEXT UNIQUE NOT NULL,
    email TEXT NOT NULL,
    avatar_url TEXT,
    bio TEXT,
    college TEXT,
    gender TEXT,
    country TEXT,
    state TEXT,
    phone TEXT,
    cri_score INT DEFAULT 0 NOT NULL,
    personality_type TEXT,
    onboarding_complete BOOLEAN DEFAULT FALSE NOT NULL,
    posts_count INT DEFAULT 0 NOT NULL,
    friends_count INT DEFAULT 0 NOT NULL,
    followers_count INT DEFAULT 0 NOT NULL,
    following_count INT DEFAULT 0 NOT NULL,
    is_online BOOLEAN DEFAULT FALSE NOT NULL,
    is_premium BOOLEAN DEFAULT FALSE NOT NULL,
    voice_call_enabled BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    total_reviews INT DEFAULT 0 NOT NULL,
    avg_empathy DOUBLE PRECISION DEFAULT 5.0 NOT NULL,
    respect_rate DOUBLE PRECISION DEFAULT 0.0 NOT NULL,
    listen_rate DOUBLE PRECISION DEFAULT 0.0 NOT NULL,
    total_calls INT DEFAULT 0 NOT NULL,
    total_call_duration INT DEFAULT 0 NOT NULL
);

-- Follows Table (Relationships)
CREATE TABLE public.follows (
    follower_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    PRIMARY KEY (follower_id, following_id)
);

-- Chat Rooms Table
CREATE TABLE public.chat_rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    participants UUID[] NOT NULL,
    last_message TEXT DEFAULT '' NOT NULL,
    last_message_time TIMESTAMPTZ DEFAULT now() NOT NULL,
    unread_counts JSONB DEFAULT '{}'::jsonb NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Messages Table (Ephemeral transit table)
CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID NOT NULL REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    text TEXT DEFAULT '' NOT NULL,
    image_url TEXT,
    file_url TEXT,
    file_name TEXT,
    timestamp TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Thoughts Table (24h Ephemeral Posts)
CREATE TABLE public.thoughts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL,
    user_avatar_url TEXT,
    text TEXT NOT NULL,
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    expires_at TIMESTAMPTZ DEFAULT (now() + interval '24 hours') NOT NULL,
    likes INT DEFAULT 0 NOT NULL,
    liked_by UUID[] DEFAULT '{}'::uuid[] NOT NULL
);

-- Thought Comments Table
CREATE TABLE public.thought_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thought_id UUID NOT NULL REFERENCES public.thoughts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL,
    user_avatar_url TEXT,
    text TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Reviews Table (Post-call feedback)
CREATE TABLE public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reviewer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    reviewed_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    empathy_score DOUBLE PRECISION NOT NULL,
    was_respectful BOOLEAN DEFAULT FALSE NOT NULL,
    did_listen BOOLEAN DEFAULT FALSE NOT NULL,
    note TEXT,
    call_type TEXT NOT NULL,
    call_duration_seconds INT DEFAULT 0 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Daily Missions Table
CREATE TABLE public.daily_missions (
    id TEXT PRIMARY KEY, -- Format: '{user_id}_{date}'
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    date TEXT NOT NULL,
    missions JSONB DEFAULT '[]'::jsonb NOT NULL,
    completed_count INT DEFAULT 0 NOT NULL,
    total_cri_earned INT DEFAULT 0 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Call Rooms Table (WebRTC)
CREATE TABLE public.rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type TEXT NOT NULL, -- 'voice' or 'video'
    status TEXT DEFAULT 'waiting' NOT NULL, -- 'waiting', 'connecting', 'connected', 'ended'
    caller_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    offer JSONB,
    answer JSONB
);

-- Caller ICE Candidates (WebRTC)
CREATE TABLE public.caller_candidates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
    candidate TEXT NOT NULL,
    "sdpMid" TEXT,
    "sdpMLineIndex" INT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Callee ICE Candidates (WebRTC)
CREATE TABLE public.callee_candidates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
    candidate TEXT NOT NULL,
    "sdpMid" TEXT,
    "sdpMLineIndex" INT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. AUTOMATED TRIGGERS & COUNTERS
-- ─────────────────────────────────────────────────────────────────────────────

-- Trigger to maintain follower, following, and friend counts
CREATE OR REPLACE FUNCTION public.handle_follows_change()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    -- Increment follower's following count
    UPDATE public.users
    SET following_count = following_count + 1
    WHERE id = NEW.follower_id;

    -- Increment following's followers count
    UPDATE public.users
    SET followers_count = followers_count + 1
    WHERE id = NEW.following_id;

    -- Check if it's a mutual follow (friendship)
    IF EXISTS (
      SELECT 1 FROM public.follows
      WHERE follower_id = NEW.following_id AND following_id = NEW.follower_id
    ) THEN
      UPDATE public.users
      SET friends_count = friends_count + 1
      WHERE id IN (NEW.follower_id, NEW.following_id);
    END IF;
    RETURN NEW;
  ELSIF (TG_OP = 'DELETE') THEN
    -- Decrement follower's following count
    UPDATE public.users
    SET following_count = GREATEST(0, following_count - 1)
    WHERE id = OLD.follower_id;

    -- Decrement following's followers count
    UPDATE public.users
    SET followers_count = GREATEST(0, followers_count - 1)
    WHERE id = OLD.following_id;

    -- Check if it was a mutual follow (friendship)
    IF EXISTS (
      SELECT 1 FROM public.follows
      WHERE follower_id = OLD.following_id AND following_id = OLD.follower_id
    ) THEN
      UPDATE public.users
      SET friends_count = GREATEST(0, friends_count - 1)
      WHERE id IN (OLD.follower_id, OLD.following_id);
    END IF;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_follows_change
AFTER INSERT OR DELETE ON public.follows
FOR EACH ROW EXECUTE FUNCTION public.handle_follows_change();


-- Trigger to maintain user posts count
CREATE OR REPLACE FUNCTION public.handle_thoughts_change()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE public.users
    SET posts_count = posts_count + 1
    WHERE id = NEW.user_id;
    RETURN NEW;
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE public.users
    SET posts_count = GREATEST(0, posts_count - 1)
    WHERE id = OLD.user_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_thoughts_change
AFTER INSERT OR DELETE ON public.thoughts
FOR EACH ROW EXECUTE FUNCTION public.handle_thoughts_change();

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- ─────────────────────────────────────────────────────────────────────────────

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.thoughts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.thought_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_missions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.caller_candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.callee_candidates ENABLE ROW LEVEL SECURITY;

-- 1. Users policies
CREATE POLICY "Allow public select for user profiles" ON public.users
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow user to insert own profile" ON public.users
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

CREATE POLICY "Allow user to update own profile" ON public.users
    FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- 2. Follows policies
CREATE POLICY "Allow select for follows" ON public.follows
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow user to follow" ON public.follows
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Allow user to unfollow" ON public.follows
    FOR DELETE TO authenticated USING (auth.uid() = follower_id);

-- 3. Chat Rooms policies
CREATE POLICY "Allow select for participating chat rooms" ON public.chat_rooms
    FOR SELECT TO authenticated USING (auth.uid() = ANY(participants));

CREATE POLICY "Allow insert for participating chat rooms" ON public.chat_rooms
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = ANY(participants));

CREATE POLICY "Allow update for participating chat rooms" ON public.chat_rooms
    FOR UPDATE TO authenticated USING (auth.uid() = ANY(participants)) WITH CHECK (auth.uid() = ANY(participants));

-- 4. Messages policies
CREATE POLICY "Allow select for messages in my rooms" ON public.messages
    FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.chat_rooms 
            WHERE id = chat_id AND auth.uid() = ANY(participants)
        )
    );

CREATE POLICY "Allow insert for messages in my rooms" ON public.messages
    FOR INSERT TO authenticated WITH CHECK (
        sender_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.chat_rooms 
            WHERE id = chat_id AND auth.uid() = ANY(participants)
        )
    );

CREATE POLICY "Allow delete for messages in my rooms" ON public.messages
    FOR DELETE TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.chat_rooms 
            WHERE id = chat_id AND auth.uid() = ANY(participants)
        )
    );

-- 5. Thoughts policies
CREATE POLICY "Allow select active thoughts" ON public.thoughts
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow insert own thoughts" ON public.thoughts
    FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

CREATE POLICY "Allow update/like thoughts" ON public.thoughts
    FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Allow delete own thoughts" ON public.thoughts
    FOR DELETE TO authenticated USING (user_id = auth.uid());

-- 6. Thought Comments policies
CREATE POLICY "Allow select thought comments" ON public.thought_comments
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow insert own comments" ON public.thought_comments
    FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

CREATE POLICY "Allow delete own comments" ON public.thought_comments
    FOR DELETE TO authenticated USING (user_id = auth.uid());

-- 7. Reviews policies
CREATE POLICY "Allow select my reviews" ON public.reviews
    FOR SELECT TO authenticated USING (reviewer_id = auth.uid() OR reviewed_user_id = auth.uid());

CREATE POLICY "Allow insert my reviews" ON public.reviews
    FOR INSERT TO authenticated WITH CHECK (reviewer_id = auth.uid());

-- 8. Daily Missions policies
CREATE POLICY "Allow select my daily missions" ON public.daily_missions
    FOR SELECT TO authenticated USING (user_id = auth.uid());

CREATE POLICY "Allow insert/upsert my daily missions" ON public.daily_missions
    FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

CREATE POLICY "Allow update my daily missions" ON public.daily_missions
    FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 9. WebRTC Rooms policies
CREATE POLICY "Allow select all call rooms" ON public.rooms
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow insert call rooms" ON public.rooms
    FOR INSERT TO authenticated WITH CHECK (caller_id = auth.uid());

CREATE POLICY "Allow update call rooms" ON public.rooms
    FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Allow delete call rooms" ON public.rooms
    FOR DELETE TO authenticated USING (caller_id = auth.uid());

-- 10. Caller ICE Candidates policies
CREATE POLICY "Allow select caller candidates" ON public.caller_candidates
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow insert caller candidates" ON public.caller_candidates
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Allow delete caller candidates" ON public.caller_candidates
    FOR DELETE TO authenticated USING (true);

-- 11. Callee ICE Candidates policies
CREATE POLICY "Allow select callee candidates" ON public.callee_candidates
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow insert callee candidates" ON public.callee_candidates
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Allow delete callee candidates" ON public.callee_candidates
    FOR DELETE TO authenticated USING (true);

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. STORAGE BUCKETS SETUP & STORAGE RLS
-- ─────────────────────────────────────────────────────────────────────────────

-- Create buckets if they don't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('chat', 'chat', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('thoughts', 'thoughts', true)
ON CONFLICT (id) DO NOTHING;

-- RLS policies for storage objects (chat bucket)
CREATE POLICY "Allow authenticated inserts to chat bucket"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'chat');

CREATE POLICY "Allow authenticated selects from chat bucket"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'chat');

CREATE POLICY "Allow authenticated updates to chat bucket"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'chat');

CREATE POLICY "Allow authenticated deletes from chat bucket"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'chat');

-- RLS policies for storage objects (thoughts bucket)
CREATE POLICY "Allow authenticated inserts to thoughts bucket"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'thoughts');

CREATE POLICY "Allow authenticated selects from thoughts bucket"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'thoughts');

CREATE POLICY "Allow authenticated updates to thoughts bucket"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'thoughts');

CREATE POLICY "Allow authenticated deletes from thoughts bucket"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'thoughts');
