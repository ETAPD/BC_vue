-- Migration: support ticket system (admin <-> user chat)

CREATE TABLE IF NOT EXISTS public.support_tickets (
  ticket_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  user_id integer NOT NULL,
  subject text NOT NULL,
  status text NOT NULL DEFAULT 'open',
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT support_tickets_pkey PRIMARY KEY (ticket_id),
  CONSTRAINT support_tickets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id ON public.support_tickets (user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON public.support_tickets (status);

CREATE TABLE IF NOT EXISTS public.ticket_messages (
  message_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  ticket_id bigint NOT NULL,
  sender_role text NOT NULL,
  sender_name text NOT NULL,
  body text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT ticket_messages_pkey PRIMARY KEY (message_id),
  CONSTRAINT ticket_messages_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.support_tickets(ticket_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_ticket_messages_ticket_id ON public.ticket_messages (ticket_id);

-- Disable RLS so authenticated users can access these tables
ALTER TABLE public.support_tickets DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_messages DISABLE ROW LEVEL SECURITY;
