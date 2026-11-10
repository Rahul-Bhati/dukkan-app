-- 004_products.sql — generated from DukaanApp_PRD.md (keep both in sync)

CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  name_hi TEXT,
  description TEXT DEFAULT '',
  price INTEGER NOT NULL CHECK (price > 0),       -- Paisa (₹99.50 = 9950)
  mrp INTEGER,                                     -- MRP for discount display
  stock_quantity INTEGER DEFAULT 0 CHECK (stock_quantity >= 0),
  unit TEXT DEFAULT 'piece',                       -- piece|kg|g|litre|ml|packet|dozen|box
  stock_alert_threshold INTEGER DEFAULT 5,
  is_in_stock BOOLEAN GENERATED ALWAYS AS (stock_quantity > 0) STORED,
  image_urls TEXT[] DEFAULT '{}',                  -- Up to 4 Supabase Storage URLs
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  search_text TEXT GENERATED ALWAYS AS (
    lower(name) || ' ' || lower(COALESCE(name_hi, '')) || ' ' || lower(COALESCE(description, ''))
  ) STORED,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_prod_category ON products(category_id) WHERE is_active = true;
CREATE INDEX idx_prod_active ON products(is_active, sort_order);
CREATE INDEX idx_prod_featured ON products(is_featured) WHERE is_featured = true AND is_active = true;
CREATE INDEX idx_prod_search ON products USING gin(search_text gin_trgm_ops);
CREATE INDEX idx_prod_stock ON products(stock_quantity) WHERE is_active = true AND stock_quantity <= 5;
