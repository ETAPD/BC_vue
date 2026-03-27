-- Migration: create admin_notifications table for admin-to-user messages
-- Run this in the Supabase SQL editor (Dashboard → SQL Editor → New query)

CREATE TABLE IF NOT EXISTS public.admin_notifications (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  user_id integer NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT admin_notifications_pkey PRIMARY KEY (id),
  CONSTRAINT admin_notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE
);

-- Index for fast per-user lookups
CREATE INDEX IF NOT EXISTS idx_admin_notifications_user_id ON public.admin_notifications (user_id);
