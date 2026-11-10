-- 005_profiles.sql — generated from DukaanApp_PRD.md (keep both in sync)

CREATE TYPE user_role AS ENUM ('customer', 'admin', 'delivery');

CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  phone TEXT NOT NULL DEFAULT '',
  full_name TEXT DEFAULT '',
  avatar_url TEXT,
  role user_role DEFAULT 'customer',
  expo_push_token TEXT,
  notifications_enabled BOOLEAN DEFAULT true,
  is_available BOOLEAN DEFAULT true,           -- Delivery person availability
  current_latitude DOUBLE PRECISION,
  current_longitude DOUBLE PRECISION,
  location_updated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_prof_role ON profiles(role);
CREATE INDEX idx_prof_delivery ON profiles(role, is_available) WHERE role = 'delivery';

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, phone, full_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.phone, ''),
    COALESCE(NEW.raw_user_meta_data->>'full_name', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
