-- Swoop Supabase Schema Extension
-- Run in Supabase SQL Editor to support full feature set

-- ── Extend profiles ──────────────────────────────────────────
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS rating DECIMAL(2,1) DEFAULT 4.8;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS plans_hosted INT DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS plans_joined INT DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS friends_count INT DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS streak_weeks INT DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS level TEXT DEFAULT 'Explorer';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS badges TEXT[] DEFAULT '{}';

-- ── Extend plans ─────────────────────────────────────────────
ALTER TABLE plans ADD COLUMN IF NOT EXISTS category TEXT;
ALTER TABLE plans ADD COLUMN IF NOT EXISTS cover_image TEXT;
ALTER TABLE plans ADD COLUMN IF NOT EXISTS is_private BOOLEAN DEFAULT true;
ALTER TABLE plans ADD COLUMN IF NOT EXISTS is_concert_mode BOOLEAN DEFAULT false;
ALTER TABLE plans ADD COLUMN IF NOT EXISTS linked_event_name TEXT;
ALTER TABLE plans ADD COLUMN IF NOT EXISTS meet_time TEXT;
ALTER TABLE plans ADD COLUMN IF NOT EXISTS event_start_time TEXT;
ALTER TABLE plans ADD COLUMN IF NOT EXISTS event_end_time TEXT;
ALTER TABLE plans ADD COLUMN IF NOT EXISTS distance_km DECIMAL(5,2);

-- ── Join requests (existing, extended) ─────────────────────
ALTER TABLE join_requests ADD COLUMN IF NOT EXISTS shared_interests TEXT[] DEFAULT '{}';
ALTER TABLE join_requests ADD COLUMN IF NOT EXISTS vibe_match_percent INT;

-- ── Activity feed ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS activity_feed (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  user_name TEXT NOT NULL,
  user_image TEXT,
  activity_type TEXT NOT NULL CHECK (activity_type IN ('joined', 'created', 'hosted')),
  plan_id UUID REFERENCES plans(id) ON DELETE SET NULL,
  plan_title TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ── User achievements ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  achievement_key TEXT NOT NULL,
  title TEXT NOT NULL,
  emoji TEXT,
  unlocked_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, achievement_key)
);

-- ── Social events index ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS social_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  event_type TEXT NOT NULL,
  venue TEXT,
  city TEXT,
  event_date TIMESTAMPTZ,
  image_url TEXT,
  search_tags TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ── Chat enhancements ────────────────────────────────────────
ALTER TABLE messages ADD COLUMN IF NOT EXISTS message_type TEXT DEFAULT 'text';
ALTER TABLE messages ADD COLUMN IF NOT EXISTS metadata JSONB;

-- ── Indexes ──────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_plans_datetime ON plans(datetime);
CREATE INDEX IF NOT EXISTS idx_plans_category ON plans(category);
CREATE INDEX IF NOT EXISTS idx_plans_linked_event ON plans(linked_event_name);
CREATE INDEX IF NOT EXISTS idx_activity_feed_created ON activity_feed(created_at DESC);

-- ── API Views ────────────────────────────────────────────────
CREATE OR REPLACE VIEW trending_plans AS
SELECT p.*, array_length(p.participants, 1) AS attendee_count
FROM plans p
WHERE p.status = 'active' AND p.datetime > now()
ORDER BY attendee_count DESC, p.is_boosted DESC;

CREATE OR REPLACE VIEW happening_soon_plans AS
SELECT * FROM plans
WHERE status = 'active'
  AND datetime BETWEEN now() AND now() + interval '1 hour'
ORDER BY datetime ASC;
