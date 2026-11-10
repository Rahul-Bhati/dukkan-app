-- 002_shop_config.sql — generated from DukaanApp_PRD.md (keep both in sync)

CREATE TABLE shop_config (
  id INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  shop_name TEXT NOT NULL DEFAULT 'My Shop',
  shop_tagline TEXT DEFAULT '',
  shop_logo_url TEXT,
  shop_banner_url TEXT,
  phone TEXT NOT NULL,
  whatsapp TEXT,
  address TEXT NOT NULL,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  delivery_fee INTEGER DEFAULT 3000,           -- Paisa (₹30.00)
  free_delivery_above INTEGER DEFAULT 50000,   -- Free delivery above ₹500
  min_order_amount INTEGER DEFAULT 10000,      -- Minimum ₹100
  delivery_radius_km FLOAT DEFAULT 5.0,
  is_open BOOLEAN DEFAULT true,
  opening_time TIME DEFAULT '09:00',
  closing_time TIME DEFAULT '21:00',
  razorpay_enabled BOOLEAN DEFAULT true,
  cod_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO shop_config (shop_name, phone, address)
VALUES ('My Shop', '+919999999999', 'Main Market, Jaipur');
