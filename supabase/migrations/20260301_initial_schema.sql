-- ============================================================
-- INITIAL SCHEMA – run this FIRST in Supabase SQL Editor
-- Dashboard → SQL Editor → New query → paste → Run
-- ============================================================

-- ── USERS ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.users (
  user_id   serial        PRIMARY KEY,
  auth_id   uuid          UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  email     text          NOT NULL,
  full_name text          NOT NULL DEFAULT '',
  initials  text          NOT NULL DEFAULT '',
  preferred_currency text NOT NULL DEFAULT 'USD',
  status    text          NOT NULL DEFAULT 'active',  -- active | suspended | admin
  role      text          NOT NULL DEFAULT 'basic',   -- basic | pro | premium | admin
  phone     text,
  country   text,
  profile_picture text,
  avatar_url text,
  created_at timestamptz  NOT NULL DEFAULT now()
);

-- ── PORTFOLIOS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.portfolios (
  portfolio_id      serial   PRIMARY KEY,
  user_id           integer  NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
  name              text     NOT NULL DEFAULT 'Main Portfolio',
  invested          numeric  NOT NULL DEFAULT 0,
  total_value       numeric  NOT NULL DEFAULT 1000,
  day_change        numeric  NOT NULL DEFAULT 0,
  day_change_percent numeric NOT NULL DEFAULT 0,
  risk_profile      text     NOT NULL DEFAULT 'moderate',
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

-- ── WATCHLISTS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.watchlists (
  watchlist_id serial    PRIMARY KEY,
  user_id      integer   NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
  name         text      NOT NULL DEFAULT 'My Watchlist',
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.watchlist_items (
  watchlist_item_id serial  PRIMARY KEY,
  watchlist_id      integer NOT NULL REFERENCES public.watchlists(watchlist_id) ON DELETE CASCADE,
  symbol            text    NOT NULL,
  current_price     numeric NOT NULL DEFAULT 0,
  change_percent    numeric NOT NULL DEFAULT 0,
  up                boolean NOT NULL DEFAULT true,
  added_at          timestamptz NOT NULL DEFAULT now()
);

-- ── ASSETS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.assets (
  asset_id    serial  PRIMARY KEY,
  symbol      text    NOT NULL UNIQUE,
  name        text    NOT NULL,
  asset_type  text    NOT NULL DEFAULT 'crypto',  -- crypto | stock | forex
  base_price  numeric NOT NULL DEFAULT 0,
  change_24h  numeric NOT NULL DEFAULT 0,
  image_url   text
);

-- ── PRICE HISTORY ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.price_history (
  id          bigserial   PRIMARY KEY,
  asset_id    integer     NOT NULL REFERENCES public.assets(asset_id) ON DELETE CASCADE,
  price       numeric     NOT NULL,
  recorded_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_price_history_asset ON public.price_history (asset_id, recorded_at);

-- ── ORDERS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.orders (
  order_id      serial   PRIMARY KEY,
  portfolio_id  integer  NOT NULL REFERENCES public.portfolios(portfolio_id) ON DELETE CASCADE,
  asset_id      integer  REFERENCES public.assets(asset_id),
  symbol        text     NOT NULL,
  order_side    text     NOT NULL,  -- buy | sell
  order_type    text     NOT NULL,  -- market | limit | stop_loss
  limit_price   numeric,
  stop_price    numeric,
  amount        numeric  NOT NULL,
  amount_unit   text     NOT NULL DEFAULT 'units',
  time_in_force text     NOT NULL DEFAULT 'gtc',
  status        text     NOT NULL DEFAULT 'pending', -- pending | active | filled | cancelled | rejected
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

-- ── TRADES ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.trades (
  trade_id     serial   PRIMARY KEY,
  portfolio_id integer  NOT NULL REFERENCES public.portfolios(portfolio_id) ON DELETE CASCADE,
  asset_id     integer  NOT NULL REFERENCES public.assets(asset_id),
  symbol       text     NOT NULL,
  trade_side   text     NOT NULL,  -- buy | sell
  amount       numeric  NOT NULL,
  price        numeric  NOT NULL,
  total        numeric  NOT NULL,
  executed_at  timestamptz NOT NULL DEFAULT now()
);

-- ── HOLDINGS ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.holdings (
  holding_id    serial   PRIMARY KEY,
  portfolio_id  integer  NOT NULL REFERENCES public.portfolios(portfolio_id) ON DELETE CASCADE,
  asset_id      integer  NOT NULL REFERENCES public.assets(asset_id),
  symbol        text     NOT NULL,
  quantity      numeric  NOT NULL DEFAULT 0,
  avg_price     numeric  NOT NULL DEFAULT 0,
  current_price numeric  NOT NULL DEFAULT 0,
  value         numeric  NOT NULL DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

-- ── USER PREFERENCES ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_preferences (
  id                      serial   PRIMARY KEY,
  user_id                 integer  NOT NULL UNIQUE REFERENCES public.users(user_id) ON DELETE CASCADE,
  notify_price_alerts     boolean  NOT NULL DEFAULT true,
  notify_order_filled     boolean  NOT NULL DEFAULT true,
  notify_order_cancelled  boolean  NOT NULL DEFAULT true,
  notify_security         boolean  NOT NULL DEFAULT true,
  updated_at              timestamptz NOT NULL DEFAULT now()
);

-- ── FUNDING METHODS ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.funding_methods (
  funding_id  serial   PRIMARY KEY,
  user_id     integer  NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
  method_type text     NOT NULL,  -- bank | card
  label       text     NOT NULL,
  last_four   text     NOT NULL,
  is_default  boolean  NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- ── CONTACT MESSAGES ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.contact_messages (
  id         serial PRIMARY KEY,
  name       text   NOT NULL,
  email      text   NOT NULL,
  subject    text   NOT NULL,
  message    text   NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ── DISABLE RLS ON ALL TABLES ──────────────────────────────
-- (for simplicity – production apps should use RLS policies)
ALTER TABLE public.users              DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.portfolios         DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.watchlists         DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.watchlist_items    DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.assets             DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.price_history      DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders             DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.trades             DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.holdings           DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences   DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.funding_methods    DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.contact_messages   DISABLE ROW LEVEL SECURITY;

-- ── SAMPLE ASSETS (crypto + stocks) ───────────────────────
INSERT INTO public.assets (symbol, name, asset_type, base_price, change_24h) VALUES
  ('BTC',  'Bitcoin',       'crypto', 67000,   2.4),
  ('ETH',  'Ethereum',      'crypto', 3500,    1.8),
  ('SOL',  'Solana',        'crypto', 185,     3.1),
  ('BNB',  'BNB',           'crypto', 420,    -0.5),
  ('XRP',  'XRP',           'crypto', 0.62,    1.2),
  ('ADA',  'Cardano',       'crypto', 0.48,   -1.1),
  ('DOGE', 'Dogecoin',      'crypto', 0.16,    4.3),
  ('AVAX', 'Avalanche',     'crypto', 38,      2.0),
  ('AAPL', 'Apple Inc.',    'stock',  189,     0.8),
  ('TSLA', 'Tesla Inc.',    'stock',  175,    -1.3),
  ('MSFT', 'Microsoft',     'stock',  415,     0.5),
  ('NVDA', 'NVIDIA',        'stock',  875,     1.7),
  ('AMZN', 'Amazon',        'stock',  185,     0.3),
  ('GOOGL','Alphabet',      'stock',  175,     0.6)
ON CONFLICT (symbol) DO NOTHING;

-- ── TRIGGER: auto-create user row on signup ────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.users (auth_id, email, full_name, initials, preferred_currency, status, role, created_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    upper(left(COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email), 2)),
    'USD',
    'active',
    'basic',
    now()
  )
  ON CONFLICT (auth_id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ── RPC: is_admin ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean LANGUAGE sql SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE auth_id = auth.uid()
      AND (role = 'admin' OR status = 'admin')
  );
$$;

-- ── RPC: set_user_role ─────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_user_role(target_user_id integer, new_role text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.users SET role = new_role WHERE user_id = target_user_id;
END;
$$;

-- ── RPC: get_user_limits ───────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_user_limits()
RETURNS json LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  user_role text;
BEGIN
  SELECT role INTO user_role FROM public.users WHERE auth_id = auth.uid();
  RETURN json_build_object(
    'role',                 COALESCE(user_role, 'basic'),
    'max_watchlist',        CASE user_role WHEN 'premium' THEN 50 WHEN 'pro' THEN 20 ELSE 10 END,
    'max_open_orders',      CASE user_role WHEN 'premium' THEN 100 WHEN 'pro' THEN 30 ELSE 10 END,
    'max_holdings',         CASE user_role WHEN 'premium' THEN 200 WHEN 'pro' THEN 50 ELSE 20 END,
    'can_export',           user_role IN ('pro', 'premium', 'admin'),
    'can_use_stop_orders',  user_role IN ('pro', 'premium', 'admin')
  );
END;
$$;
