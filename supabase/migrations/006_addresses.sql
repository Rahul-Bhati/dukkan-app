-- 006_addresses.sql — generated from DukaanApp_PRD.md (keep both in sync)

CREATE TABLE addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  label TEXT DEFAULT 'Home',                    -- Home | Work | Other
  full_address TEXT NOT NULL,
  landmark TEXT,
  city TEXT DEFAULT '',
  pincode VARCHAR(6),
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_addr_user ON addresses(user_id);
CREATE UNIQUE INDEX idx_addr_default ON addresses(user_id) WHERE is_default = true;
