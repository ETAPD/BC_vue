-- Migration: add phone to users, remove unused theme/language from user_preferences
-- Run this in the Supabase SQL editor (Dashboard → SQL Editor → New query)

-- 1. Add phone column to users table
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS phone text;

-- 2. Drop theme and language from user_preferences (no longer used in the app UI)
ALTER TABLE public.user_preferences
  DROP COLUMN IF EXISTS theme,
  DROP COLUMN IF EXISTS language;
