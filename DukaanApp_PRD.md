# DukaanApp — Implementation PRD

> **Follow each milestone in order. Complete all acceptance tests before moving to the next.**

---

## PROJECT OVERVIEW

A mobile app for a single shop with 3 modules in one codebase:
1. **Customer App** — browse, cart, pay, track delivery
2. **Shopkeeper Panel** — manage products/orders/earnings
3. **Delivery View** — pending deliveries, navigate, live location, mark delivered

**Stack:**
- **App:** React Native (Expo SDK 52+, Expo Router)
- **Backend:** Supabase free tier (PostgreSQL + Auth + Realtime + Storage + Edge Functions)
- **Payments:** Razorpay React Native SDK
- **Maps:** react-native-maps + expo-location + Google Maps API
- **Notifications:** expo-notifications + Firebase Cloud Messaging
- **State:** Zustand (cart, auth)
- **Build:** Expo EAS (APK/AAB)

**Total running cost: ₹0/month** (within Supabase + Google Maps free tiers, Razorpay charges 2% per transaction only)

---

## THREE MODULES — SCREEN MAP

### MODULE 1: Customer App

| Screen | Route | Purpose |
|--------|-------|---------|
| Login | `(auth)/login` | Phone number input, send OTP |
| Verify OTP | `(auth)/verify-otp` | 6-digit OTP verification |
| Home | `(customer)/home` | Shop banner, categories, featured products, all products grid |
| Category | `(customer)/category/[id]` | Products filtered by category with sort |
| Product Detail | `(customer)/product/[id]` | Image carousel, price, description, add to cart |
| Search | `(customer)/search` | Fuzzy search with debounce, recent searches |
| Cart | `(customer)/cart` | Items with +/- quantity, price breakdown, checkout button |
| Checkout | `(customer)/checkout` | Address selector, payment method, place order |
| Add Address | `(customer)/add-address` | Manual input or GPS, map preview, save |
| Payment | Razorpay native sheet | UPI / Card / Wallet / Net Banking |
| Order Confirmation | `(customer)/order-success` | Success animation, order number, track button |
| My Orders | `(customer)/orders` | Order history list with status badges |
| Order Detail | `(customer)/orders/[id]` | Status timeline, items, price, cancel option |
| Live Tracking | `(customer)/orders/track/[id]` | Map with delivery person moving marker |
| Profile | `(customer)/profile` | Name, phone, addresses, notifications, logout |
| Manage Addresses | `(customer)/addresses` | List, add, edit, delete, set default |

### MODULE 2: Shopkeeper Panel

| Screen | Route | Purpose |
|--------|-------|---------|
| Dashboard | `(admin)/dashboard` | Today's orders, revenue, pending count, low stock alerts |
| Order List | `(admin)/orders` | Tabs: New / In Progress / Out for Delivery / Completed / Cancelled |
| Order Detail | `(admin)/orders/[id]` | Customer info, items, status action buttons, assign delivery |
| Product List | `(admin)/products` | All products with search, filter, active toggle |
| Add/Edit Product | `(admin)/products/[id]` | Form: name, price, images, category, stock, unit |
| Category Manager | `(admin)/categories` | Add, edit, reorder, delete categories |
| Earnings | `(admin)/earnings` | Today/week/month revenue, order count, transaction list |
| Delivery Staff | `(admin)/delivery-staff` | Add/remove delivery persons by phone |
| Shop Settings | `(admin)/settings` | Name, logo, address, hours, delivery fee, min order, COD toggle |

### MODULE 3: Delivery View

| Screen | Route | Purpose |
|--------|-------|---------|
| My Deliveries | `(delivery)/index` | List of assigned orders (ready + out for delivery) |
| Delivery Detail | `(delivery)/[id]` | Order items, customer name/phone/address, navigate button, start delivery |
| Mark Delivered | `(delivery)/confirm/[id]` | Confirm delivery, COD amount collection |

---

## REPO STRUCTURE

> **As built (Expo SDK 57) — differs from the tree below in three ways:**
> 1. All app code lives under `src/` (`src/app`, `src/components`, `src/lib`, `src/hooks`, `src/types`), the current Expo Router convention. Import with the `@/` alias (`@/lib/auth`).
> 2. Shopkeeper and delivery routes are real path segments `src/app/admin/…` and `src/app/delivery/…`, not `(admin)`/`(delivery)` groups. Groups don't change URLs, so `(customer)/orders/[id]` and `(admin)/orders/[id]` would both resolve to `/orders/[id]` and clash; the same goes for `(delivery)/index` vs the root `index`. URLs: customer `/home`, admin `/admin/dashboard`, delivery `/delivery`.
> 3. Tab screens sit in a nested `(tabs)` group inside each module (`(customer)/(tabs)/home.tsx`, `admin/(tabs)/dashboard.tsx`). Detail screens (product, checkout, order detail…) are in the module's Stack, so they open full-screen over the tab bar.
>
> Role routing uses `Stack.Protected` guards in `src/app/_layout.tsx`. Icons come from `lucide-react-native` (SDK 57 no longer bundles `@expo/vector-icons`).

```
dukaan-app/
├── app/
│   ├── _layout.tsx                    # Root: AuthProvider + role-based redirect
│   ├── index.tsx                      # Splash → check auth → redirect
│   ├── (auth)/
│   │   ├── _layout.tsx
│   │   ├── login.tsx
│   │   └── verify-otp.tsx
│   ├── (customer)/
│   │   ├── _layout.tsx                # Bottom Tabs: Home, Cart, Orders, Profile
│   │   ├── home.tsx
│   │   ├── category/[id].tsx
│   │   ├── product/[id].tsx
│   │   ├── search.tsx
│   │   ├── cart.tsx
│   │   ├── checkout.tsx
│   │   ├── add-address.tsx
│   │   ├── order-success.tsx
│   │   ├── orders/index.tsx
│   │   ├── orders/[id].tsx
│   │   ├── orders/track/[id].tsx
│   │   ├── profile.tsx
│   │   └── addresses.tsx
│   ├── (admin)/
│   │   ├── _layout.tsx                # Bottom Tabs: Dashboard, Products, Orders, Settings
│   │   ├── dashboard.tsx
│   │   ├── orders/index.tsx
│   │   ├── orders/[id].tsx
│   │   ├── products/index.tsx
│   │   ├── products/[id].tsx          # id='new' for add, UUID for edit
│   │   ├── categories.tsx
│   │   ├── earnings.tsx
│   │   ├── delivery-staff.tsx
│   │   └── settings.tsx
│   └── (delivery)/
│       ├── _layout.tsx                # Simple stack
│       ├── index.tsx
│       ├── [id].tsx
│       └── confirm/[id].tsx
├── components/
│   ├── ui/                            # Button, Input, Card, Badge, Modal, Toast, Skeleton, EmptyState, SearchBar
│   ├── customer/                      # ProductCard, ProductCarousel, QuantitySelector, CategoryChip,
│   │                                  # CartItem, CartSummary, CartBadge, OrderCard, OrderTimeline,
│   │                                  # AddressCard, DeliveryMap
│   ├── admin/                         # StatCard, AdminOrderCard, StatusActionButton, ProductRow,
│   │                                  # ProductForm, ImageUploader, CategoryRow, EarningsChart
│   └── delivery/                      # DeliveryCard, LocationToggle
├── lib/
│   ├── supabase.ts                    # Client init with SecureStore adapter
│   ├── auth.tsx                       # AuthProvider: user, profile, role, signIn/Out
│   ├── cart.ts                        # Zustand store: items, add, remove, clear, total
│   ├── razorpay.ts                    # createOrder + openCheckout + verifyPayment
│   ├── notifications.ts              # Register token, save to profile, handle tap
│   ├── location.ts                    # startTracking, stopTracking, getCurrentPosition
│   ├── storage.ts                     # uploadImage, deleteImage (Supabase Storage)
│   ├── constants.ts                   # ORDER_STATUSES, UNITS, colors
│   └── utils.ts                       # formatPrice, formatDate, formatPhone
├── hooks/
│   ├── useProducts.ts                 # Fetch with category/search/sort/pagination
│   ├── useCategories.ts
│   ├── useOrders.ts                   # Fetch orders (customer: own, admin: all)
│   ├── useOrderDetail.ts             # Single order with realtime subscription
│   ├── useCart.ts
│   ├── useShopConfig.ts
│   ├── useAdminStats.ts
│   ├── useDeliveryOrders.ts
│   └── useDeliveryTracking.ts         # Subscribe to delivery_locations realtime
├── types/index.ts
├── assets/
├── supabase/
│   ├── migrations/                    # 001-012 SQL files
│   ├── functions/                     # Edge functions: create-order, verify-payment, razorpay-webhook,
│   │                                  # process-refund, send-push
│   └── seed.sql
├── app.json
├── eas.json
├── package.json
└── .env
```

---

## ENVIRONMENT VARIABLES

### App (.env)
```
EXPO_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=eyJ...
EXPO_PUBLIC_RAZORPAY_KEY_ID=rzp_test_xxx
EXPO_PUBLIC_GOOGLE_MAPS_API_KEY=AIza...
EXPO_PUBLIC_SHOP_NAME=Krishna General Store
```

### Supabase Edge Function Secrets (set via dashboard)
```
RAZORPAY_KEY_ID=rzp_test_xxx
RAZORPAY_KEY_SECRET=xxx_secret
RAZORPAY_WEBHOOK_SECRET=xxx              # Set when creating the webhook in Razorpay Dashboard
INTERNAL_FUNCTION_SECRET=<random 32+ chars>  # Shared by DB triggers/cron → internal edge functions
EXPO_ACCESS_TOKEN=xxx
```

### Supabase Vault Secrets (run once in SQL editor, BEFORE migration 012 — never commit these)
```sql
SELECT vault.create_secret('https://xxx.supabase.co', 'project_url');
SELECT vault.create_secret('<same value as INTERNAL_FUNCTION_SECRET>', 'internal_secret');
```

---

## SECURITY RULES (non-negotiable — apply in every milestone)

1. **The client never writes to `orders` or `order_status_log` directly.** There are no INSERT/UPDATE policies on them. All changes go through `create-order` (edge function) or the RPCs `update_order_status` / `set_admin_note`.
2. **Prices, totals, stock and payment status are decided only on the server.** The client sends product IDs + quantities, nothing else.
3. **Stock is reserved when the order is created**, inside the same transaction, with a conditional `UPDATE ... WHERE stock_quantity >= qty`. It is released exactly once, when the order is cancelled (`stock_reserved` flag).
4. **Razorpay webhook is the source of truth for payment.** `verify-payment` is the fast path; the webhook covers app-killed / network-lost cases. Both call the same idempotent `mark_order_paid()`.
5. **Users cannot change their own `role` or `phone`** (trigger `protect_profile_columns`). Only admins can change roles.
6. **Internal SQL functions are not callable from the app.** Supabase grants EXECUTE on every public function to `anon`/`authenticated` by default — migration 010 revokes it from everything internal.
7. **Every `SECURITY DEFINER` function sets `search_path = public`** and checks the caller's permission itself.
8. **Cancelling a paid online order always triggers an automatic Razorpay refund** (`refund_pending` → `process-refund` → `refunded`).

---

## DATABASE SCHEMA

### 001_extensions.sql
```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;  -- scheduled jobs (order expiry, refund retry)
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;   -- DB → edge function HTTP calls
```

### 002_shop_config.sql
```sql
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
```

### 003_categories.sql
```sql
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  name_hi TEXT,
  image_url TEXT,
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_cat_sort ON categories(sort_order ASC);
```

### 004_products.sql
```sql
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
```

### 005_profiles.sql
```sql
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
```

### 006_addresses.sql
```sql
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
```

### 007_orders.sql
```sql
CREATE TYPE order_status AS ENUM (
  'placed',             -- Customer placed, waiting for shopkeeper
  'confirmed',          -- Shopkeeper accepted
  'preparing',          -- Being packed
  'ready',              -- Ready for delivery pickup
  'out_for_delivery',   -- Delivery person has it
  'delivered',          -- Done
  'cancelled'           -- Cancelled by customer or shopkeeper
);

CREATE TYPE payment_method AS ENUM ('razorpay', 'cod');
CREATE TYPE payment_status AS ENUM (
  'pending',          -- Online: awaiting payment. COD: not yet collected
  'paid',             -- Online: captured. COD: collected on delivery
  'failed',           -- Last online attempt failed (customer may retry until the order expires)
  'refund_pending',   -- Paid order was cancelled → refund queued/in progress
  'refunded'          -- Razorpay confirmed refund (refund.processed webhook)
);

CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number INTEGER GENERATED ALWAYS AS IDENTITY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  status order_status DEFAULT 'placed',
  status_updated_at TIMESTAMPTZ DEFAULT NOW(),
  -- Items snapshot (denormalized — prices locked at time of order)
  items JSONB NOT NULL,
  -- [{"product_id":"uuid","name":"Toor Dal","price":8500,"mrp":9500,"quantity":2,"unit":"kg","image_url":"..."}]
  subtotal INTEGER NOT NULL,                    -- Paisa
  delivery_fee INTEGER DEFAULT 0,
  discount INTEGER DEFAULT 0,
  total INTEGER NOT NULL,
  payment_method payment_method NOT NULL,
  payment_status payment_status DEFAULT 'pending',
  razorpay_order_id VARCHAR(100),
  razorpay_payment_id VARCHAR(100),
  razorpay_signature VARCHAR(200),
  paid_at TIMESTAMPTZ,
  razorpay_refund_id VARCHAR(100),
  refund_attempted_at TIMESTAMPTZ,              -- Claim marker so two refund workers never refund twice
  refunded_at TIMESTAMPTZ,
  stock_reserved BOOLEAN NOT NULL DEFAULT true, -- true while this order holds stock; flipped once on cancel
  delivery_address JSONB NOT NULL,
  -- {"full_address":"...","landmark":"...","latitude":26.9,"longitude":75.7,"phone":"+91...","name":"..."}
  delivery_person_id UUID REFERENCES auth.users(id),
  estimated_delivery_minutes INTEGER DEFAULT 45,
  delivered_at TIMESTAMPTZ,
  customer_note TEXT,
  admin_note TEXT,
  cancellation_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ord_user ON orders(user_id, created_at DESC);
CREATE INDEX idx_ord_status ON orders(status) WHERE status NOT IN ('delivered', 'cancelled');
CREATE INDEX idx_ord_delivery ON orders(delivery_person_id) WHERE delivery_person_id IS NOT NULL;
CREATE INDEX idx_ord_date ON orders(created_at DESC);
CREATE UNIQUE INDEX idx_ord_rzp_order ON orders(razorpay_order_id) WHERE razorpay_order_id IS NOT NULL;
CREATE INDEX idx_ord_rzp_payment ON orders(razorpay_payment_id) WHERE razorpay_payment_id IS NOT NULL;
CREATE INDEX idx_ord_unpaid ON orders(created_at)
  WHERE payment_method = 'razorpay' AND payment_status IN ('pending', 'failed') AND status = 'placed';
CREATE INDEX idx_ord_refund ON orders(payment_status) WHERE payment_status = 'refund_pending';

-- Status history for timeline display
CREATE TABLE order_status_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  from_status order_status,
  to_status order_status NOT NULL,
  changed_by UUID REFERENCES auth.users(id),
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_log_order ON order_status_log(order_id, created_at ASC);
```

### 008_delivery.sql
```sql
CREATE TABLE delivery_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  delivery_person_id UUID NOT NULL REFERENCES auth.users(id),
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  heading FLOAT,
  speed FLOAT,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_dloc_order ON delivery_locations(order_id, recorded_at DESC);

-- Get latest location for an order.
-- SECURITY INVOKER (default) on purpose: RLS on delivery_locations decides who may see it.
-- (SECURITY DEFINER here would let any user read any order's live location.)
CREATE OR REPLACE FUNCTION get_latest_delivery_location(p_order_id UUID)
RETURNS TABLE(
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  heading FLOAT,
  speed FLOAT,
  recorded_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
    SELECT dl.latitude, dl.longitude, dl.heading, dl.speed, dl.recorded_at
    FROM delivery_locations dl
    WHERE dl.order_id = p_order_id
    ORDER BY dl.recorded_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path = public;

-- Cleanup old locations (keep last 24h only). Run by pg_cron (012) — not callable from the app.
CREATE OR REPLACE FUNCTION cleanup_delivery_locations()
RETURNS void AS $$
BEGIN
  DELETE FROM delivery_locations WHERE recorded_at < NOW() - INTERVAL '24 hours';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
```

### 009_rls.sql
```sql
ALTER TABLE shop_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_status_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_locations ENABLE ROW LEVEL SECURITY;

-- Helper: check admin role
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

-- SHOP CONFIG
CREATE POLICY "anyone_reads_shop" ON shop_config FOR SELECT USING (true);
CREATE POLICY "admin_updates_shop" ON shop_config FOR UPDATE USING (is_admin());

-- CATEGORIES
CREATE POLICY "anyone_reads_categories" ON categories FOR SELECT USING (true);
CREATE POLICY "admin_writes_categories" ON categories FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "admin_updates_categories" ON categories FOR UPDATE USING (is_admin());
CREATE POLICY "admin_deletes_categories" ON categories FOR DELETE USING (is_admin());

-- PRODUCTS
CREATE POLICY "public_reads_active_products" ON products FOR SELECT USING (is_active = true OR is_admin());
CREATE POLICY "admin_inserts_products" ON products FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "admin_updates_products" ON products FOR UPDATE USING (is_admin());
CREATE POLICY "admin_deletes_products" ON products FOR DELETE USING (is_admin());

-- PROFILES
CREATE POLICY "own_profile_read" ON profiles FOR SELECT USING (id = auth.uid() OR is_admin());
CREATE POLICY "own_profile_update" ON profiles FOR UPDATE
  USING (id = auth.uid()) WITH CHECK (id = auth.uid());
-- Needed by Delivery Staff screen (admin sets role='delivery' / 'customer' on other users)
CREATE POLICY "admin_updates_profiles" ON profiles FOR UPDATE
  USING (is_admin()) WITH CHECK (is_admin());

-- RLS is per-row, not per-column: "own_profile_update" alone would let a customer
-- run `update profiles set role='admin'` on their own row. This trigger blocks that.
CREATE OR REPLACE FUNCTION protect_profile_columns()
RETURNS TRIGGER AS $$
BEGIN
  -- auth.uid() IS NULL → service_role (edge functions) or SQL editor: trusted
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;
  IF NEW.role IS DISTINCT FROM OLD.role AND NOT is_admin() THEN
    RAISE EXCEPTION 'FORBIDDEN: only admins can change roles' USING ERRCODE = '42501';
  END IF;
  IF NEW.phone IS DISTINCT FROM OLD.phone THEN
    RAISE EXCEPTION 'FORBIDDEN: phone is managed by auth' USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trg_protect_profile_columns
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION protect_profile_columns();

-- ADDRESSES
CREATE POLICY "own_addresses" ON addresses FOR ALL
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ORDERS — READ ONLY from the app.
-- No INSERT policy: orders are created only by the create-order edge function (service role),
--   otherwise a customer could insert an order with any price/total.
-- No UPDATE policy: status changes go through update_order_status(), admin notes through
--   set_admin_note(). A table-level UPDATE policy would let admins/delivery staff rewrite
--   totals, payment_status, items, etc.
CREATE POLICY "customer_reads_own_orders" ON orders FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "admin_reads_all_orders" ON orders FOR SELECT USING (is_admin());
CREATE POLICY "delivery_reads_assigned" ON orders FOR SELECT USING (delivery_person_id = auth.uid());

-- ORDER STATUS LOG — READ ONLY. Rows are written only by apply_order_transition() / place_order().
CREATE POLICY "read_order_logs" ON order_status_log FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM orders o
    WHERE o.id = order_id
      AND (o.user_id = auth.uid() OR o.delivery_person_id = auth.uid() OR is_admin())
  ));

-- DELIVERY LOCATIONS
CREATE POLICY "customer_tracks_own" ON delivery_locations FOR SELECT
  USING (EXISTS (SELECT 1 FROM orders o WHERE o.id = order_id AND o.user_id = auth.uid()));
CREATE POLICY "admin_tracks_all" ON delivery_locations FOR SELECT USING (is_admin());
-- Only the assigned delivery person, only while the order is actually out for delivery
-- (otherwise anyone could inject fake positions into another customer's tracking map).
CREATE POLICY "delivery_shares_location" ON delivery_locations FOR INSERT
  WITH CHECK (
    delivery_person_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM orders o
      WHERE o.id = order_id
        AND o.delivery_person_id = auth.uid()
        AND o.status = 'out_for_delivery'
    )
  );
```

### 010_functions.sql
```sql
-- ============================================================
-- ORDER CREATION (internal — called only by the create-order edge function)
-- One transaction: prices from DB, atomic stock reservation, totals, insert.
-- If anything fails, everything rolls back (no half-reserved stock).
-- ============================================================
CREATE OR REPLACE FUNCTION place_order(
  p_user_id UUID,
  p_items JSONB,                    -- [{"product_id":"uuid","quantity":2}] — client prices are never accepted
  p_address_id UUID,
  p_payment_method payment_method,
  p_customer_note TEXT DEFAULT NULL
) RETURNS orders AS $$
DECLARE
  v_shop shop_config;
  v_addr addresses;
  v_phone TEXT;
  v_name TEXT;
  v_item RECORD;
  v_prod products;
  v_snapshot JSONB := '[]'::jsonb;
  v_subtotal INTEGER := 0;
  v_fee INTEGER;
  v_order orders;
BEGIN
  SELECT * INTO v_shop FROM shop_config WHERE id = 1;
  IF NOT v_shop.is_open THEN RAISE EXCEPTION 'SHOP_CLOSED'; END IF;
  IF p_payment_method = 'cod' AND NOT v_shop.cod_enabled THEN RAISE EXCEPTION 'COD_DISABLED'; END IF;
  IF p_payment_method = 'razorpay' AND NOT v_shop.razorpay_enabled THEN RAISE EXCEPTION 'ONLINE_PAYMENT_DISABLED'; END IF;

  IF jsonb_typeof(p_items) <> 'array' OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'EMPTY_CART';
  END IF;
  IF jsonb_array_length(p_items) > 50 THEN
    RAISE EXCEPTION 'TOO_MANY_ITEMS';
  END IF;
  IF EXISTS (
    SELECT 1 FROM jsonb_array_elements(p_items) AS e(item)
    WHERE (e.item->>'quantity')::INTEGER IS NULL OR (e.item->>'quantity')::INTEGER < 1
  ) THEN
    RAISE EXCEPTION 'INVALID_QUANTITY';
  END IF;

  SELECT * INTO v_addr FROM addresses WHERE id = p_address_id AND user_id = p_user_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'ADDRESS_NOT_FOUND'; END IF;
  SELECT phone, full_name INTO v_phone, v_name FROM profiles WHERE id = p_user_id;

  -- Merge duplicate product_ids, lock rows in a fixed order (→ no deadlocks between checkouts)
  FOR v_item IN
    SELECT (e.item->>'product_id')::UUID AS product_id,
           SUM((e.item->>'quantity')::INTEGER)::INTEGER AS quantity
      FROM jsonb_array_elements(p_items) AS e(item)
     GROUP BY 1
     ORDER BY 1
  LOOP
    IF v_item.quantity > 100 THEN RAISE EXCEPTION 'INVALID_QUANTITY'; END IF;

    -- Atomic reserve: only succeeds if enough stock exists at this instant.
    -- A concurrent checkout waits on the row lock, then re-checks stock → no overselling.
    UPDATE products
       SET stock_quantity = stock_quantity - v_item.quantity,
           updated_at = NOW()
     WHERE id = v_item.product_id
       AND is_active = true
       AND stock_quantity >= v_item.quantity
    RETURNING * INTO v_prod;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'OUT_OF_STOCK:%', v_item.product_id;   -- whole transaction rolls back
    END IF;

    v_subtotal := v_subtotal + v_prod.price * v_item.quantity;
    v_snapshot := v_snapshot || jsonb_build_object(
      'product_id', v_prod.id,
      'name',       v_prod.name,
      'price',      v_prod.price,
      'mrp',        v_prod.mrp,
      'quantity',   v_item.quantity,
      'unit',       v_prod.unit,
      'image_url',  v_prod.image_urls[1]
    );
  END LOOP;

  IF v_subtotal < v_shop.min_order_amount THEN RAISE EXCEPTION 'BELOW_MIN_ORDER'; END IF;
  v_fee := CASE WHEN v_subtotal >= v_shop.free_delivery_above THEN 0 ELSE v_shop.delivery_fee END;

  INSERT INTO orders (
    user_id, items, subtotal, delivery_fee, total, payment_method,
    delivery_address, customer_note, stock_reserved
  ) VALUES (
    p_user_id, v_snapshot, v_subtotal, v_fee, v_subtotal + v_fee, p_payment_method,
    jsonb_build_object(
      'full_address', v_addr.full_address, 'landmark', v_addr.landmark,
      'city', v_addr.city, 'pincode', v_addr.pincode,
      'latitude', v_addr.latitude, 'longitude', v_addr.longitude,
      'phone', v_phone, 'name', v_name
    ),
    left(p_customer_note, 500), true
  ) RETURNING * INTO v_order;

  INSERT INTO order_status_log (order_id, from_status, to_status, changed_by)
  VALUES (v_order.id, NULL, 'placed', p_user_id);

  RETURN v_order;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================
-- ORDER STATE MACHINE (internal — the ONLY code that changes order status)
-- Locks the row, enforces allowed transitions, releases stock exactly once,
-- marks COD as paid on delivery, queues refunds for paid cancellations.
-- ============================================================
CREATE OR REPLACE FUNCTION apply_order_transition(
  p_order_id UUID,
  p_new_status order_status,
  p_actor UUID DEFAULT NULL,                   -- NULL = system (cron / edge function)
  p_note TEXT DEFAULT NULL,
  p_delivery_person_id UUID DEFAULT NULL,
  p_expected_status order_status DEFAULT NULL  -- reject if the order moved on in the meantime
) RETURNS orders AS $$
DECLARE
  v_order orders;
  v_old order_status;
BEGIN
  -- Row lock: concurrent cancel / accept / deliver calls are serialized
  SELECT * INTO v_order FROM orders WHERE id = p_order_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'ORDER_NOT_FOUND'; END IF;
  v_old := v_order.status;

  IF p_expected_status IS NOT NULL AND v_old <> p_expected_status THEN
    RAISE EXCEPTION 'ORDER_STATUS_CHANGED:%', v_old;
  END IF;

  -- Allowed transitions. Everything else (incl. cancelled → cancelled) is rejected,
  -- which is what makes stock restore and refunds impossible to trigger twice.
  IF NOT (
       (v_old = 'placed'           AND p_new_status IN ('confirmed', 'cancelled'))
    OR (v_old = 'confirmed'        AND p_new_status IN ('preparing', 'cancelled'))
    OR (v_old = 'preparing'        AND p_new_status IN ('ready', 'cancelled'))
    OR (v_old = 'ready'            AND p_new_status IN ('out_for_delivery', 'cancelled'))
    OR (v_old = 'out_for_delivery' AND p_new_status = 'delivered')
  ) THEN
    RAISE EXCEPTION 'INVALID_TRANSITION:%->%', v_old, p_new_status;
  END IF;

  -- Online orders cannot be processed until payment is confirmed
  IF p_new_status <> 'cancelled'
     AND v_order.payment_method = 'razorpay'
     AND v_order.payment_status <> 'paid' THEN
    RAISE EXCEPTION 'PAYMENT_NOT_CONFIRMED';
  END IF;

  IF p_delivery_person_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM profiles WHERE id = p_delivery_person_id AND role = 'delivery'
  ) THEN
    RAISE EXCEPTION 'INVALID_DELIVERY_PERSON';
  END IF;

  IF p_new_status = 'out_for_delivery'
     AND COALESCE(p_delivery_person_id, v_order.delivery_person_id) IS NULL THEN
    RAISE EXCEPTION 'NO_DELIVERY_PERSON';
  END IF;

  -- Release reserved stock exactly once (stock_reserved flips to false below)
  IF p_new_status = 'cancelled' AND v_order.stock_reserved THEN
    UPDATE products p
       SET stock_quantity = p.stock_quantity + (i.item->>'quantity')::INTEGER,
           updated_at = NOW()
      FROM jsonb_array_elements(v_order.items) AS i(item)
     WHERE p.id = (i.item->>'product_id')::UUID;
  END IF;

  UPDATE orders SET
    status              = p_new_status,
    status_updated_at   = NOW(),
    updated_at          = NOW(),
    delivery_person_id  = COALESCE(p_delivery_person_id, delivery_person_id),
    delivered_at        = CASE WHEN p_new_status = 'delivered' THEN NOW() ELSE delivered_at END,
    cancellation_reason = CASE WHEN p_new_status = 'cancelled' THEN p_note ELSE cancellation_reason END,
    stock_reserved      = CASE WHEN p_new_status = 'cancelled' THEN false ELSE stock_reserved END,
    payment_status = CASE
      -- COD cash is collected at the door → counts as revenue once delivered
      WHEN p_new_status = 'delivered' AND payment_method = 'cod' THEN 'paid'::payment_status
      -- Paid online order cancelled → refund (trigger in 012 calls process-refund)
      WHEN p_new_status = 'cancelled' AND payment_status = 'paid' THEN 'refund_pending'::payment_status
      ELSE payment_status
    END,
    paid_at = CASE
      WHEN p_new_status = 'delivered' AND payment_method = 'cod' THEN NOW()
      ELSE paid_at
    END
  WHERE id = p_order_id
  RETURNING * INTO v_order;

  INSERT INTO order_status_log (order_id, from_status, to_status, changed_by, note)
  VALUES (p_order_id, v_old, p_new_status, p_actor, p_note);

  RETURN v_order;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================
-- PUBLIC: supabase.rpc('update_order_status', {...}) from the app.
-- Decides WHO may perform WHICH transition, then delegates.
--   admin    : any valid transition; may assign a delivery person
--   customer : own order only, 'placed' → 'cancelled' only
--   delivery : assigned order only, → 'out_for_delivery' / 'delivered'
-- ============================================================
CREATE OR REPLACE FUNCTION update_order_status(
  p_order_id UUID,
  p_new_status order_status,
  p_note TEXT DEFAULT NULL,
  p_delivery_person_id UUID DEFAULT NULL
) RETURNS void AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_order orders;
  v_expected order_status;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHENTICATED' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_order FROM orders WHERE id = p_order_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'ORDER_NOT_FOUND'; END IF;

  IF is_admin() THEN
    v_expected := NULL;
  ELSIF v_order.user_id = v_uid THEN
    IF p_new_status <> 'cancelled' OR p_delivery_person_id IS NOT NULL THEN
      RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE = '42501';
    END IF;
    v_expected := 'placed';   -- fails cleanly if the shop accepted it a second ago
  ELSIF v_order.delivery_person_id = v_uid THEN
    IF p_new_status NOT IN ('out_for_delivery', 'delivered') OR p_delivery_person_id IS NOT NULL THEN
      RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE = '42501';
    END IF;
    v_expected := NULL;
  ELSE
    RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE = '42501';
  END IF;

  PERFORM apply_order_transition(
    p_order_id, p_new_status, v_uid, left(p_note, 500), p_delivery_person_id, v_expected
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- PUBLIC: admin note is the only order field the app may edit directly
CREATE OR REPLACE FUNCTION set_admin_note(p_order_id UUID, p_note TEXT)
RETURNS void AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE = '42501';
  END IF;
  UPDATE orders SET admin_note = left(p_note, 1000), updated_at = NOW() WHERE id = p_order_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================
-- PAYMENTS (internal — called by verify-payment and razorpay-webhook)
-- Idempotent: whichever of the two arrives first wins, the other is a no-op.
-- Returns result: 'paid' | 'already_processed' | 'refund_queued'
-- Only send the "New Order" push when result = 'paid' (prevents duplicate pushes).
-- ============================================================
CREATE OR REPLACE FUNCTION mark_order_paid(
  p_razorpay_order_id TEXT,
  p_payment_id TEXT,
  p_signature TEXT DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
  v_order orders;
  v_result TEXT;
BEGIN
  SELECT * INTO v_order FROM orders WHERE razorpay_order_id = p_razorpay_order_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'ORDER_NOT_FOUND'; END IF;

  IF v_order.payment_status IN ('paid', 'refund_pending', 'refunded') THEN
    v_result := 'already_processed';
  ELSIF v_order.status = 'cancelled' THEN
    -- Money arrived after the order expired / was cancelled (stock already released) → refund it
    UPDATE orders SET
      payment_status = 'refund_pending',
      razorpay_payment_id = p_payment_id,
      razorpay_signature = COALESCE(p_signature, razorpay_signature),
      paid_at = NOW(), updated_at = NOW()
    WHERE id = v_order.id;
    v_result := 'refund_queued';
  ELSE
    UPDATE orders SET
      payment_status = 'paid',
      razorpay_payment_id = p_payment_id,
      razorpay_signature = COALESCE(p_signature, razorpay_signature),
      paid_at = NOW(), updated_at = NOW()
    WHERE id = v_order.id;
    v_result := 'paid';
  END IF;

  RETURN json_build_object(
    'result', v_result,
    'order_id', v_order.id,
    'order_number', v_order.order_number,
    'total', v_order.total,
    'item_count', jsonb_array_length(v_order.items)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- A failed attempt does NOT cancel the order: Razorpay lets the customer retry on the
-- same razorpay_order_id. Unpaid orders are cancelled by expire_unpaid_orders().
CREATE OR REPLACE FUNCTION mark_payment_failed(p_razorpay_order_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE orders SET payment_status = 'failed', updated_at = NOW()
  WHERE razorpay_order_id = p_razorpay_order_id AND payment_status = 'pending';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Cancel online orders that were never paid, releasing their reserved stock.
-- Runs every 5 min via pg_cron (012). Razorpay checkout uses timeout: 900 (15 min),
-- so no payment can complete after the 20-min cutoff.
CREATE OR REPLACE FUNCTION expire_unpaid_orders()
RETURNS INTEGER AS $$
DECLARE
  v_id UUID;
  v_count INTEGER := 0;
BEGIN
  FOR v_id IN
    SELECT id FROM orders
     WHERE payment_method = 'razorpay'
       AND payment_status IN ('pending', 'failed')
       AND status = 'placed'
       AND created_at < NOW() - INTERVAL '20 minutes'
     FOR UPDATE SKIP LOCKED      -- skip orders a payment callback is touching right now
  LOOP
    PERFORM apply_order_transition(v_id, 'cancelled', NULL, 'Payment not completed in time', NULL, 'placed');
    v_count := v_count + 1;
  END LOOP;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Claim refunds atomically so two process-refund runs can never refund the same order.
-- A claim expires after 10 min so a crashed run gets retried.
CREATE OR REPLACE FUNCTION claim_refunds(p_order_id UUID DEFAULT NULL)
RETURNS SETOF orders AS $$
  UPDATE orders SET refund_attempted_at = NOW()
   WHERE payment_status = 'refund_pending'
     AND razorpay_payment_id IS NOT NULL
     AND razorpay_refund_id IS NULL
     AND (refund_attempted_at IS NULL OR refund_attempted_at < NOW() - INTERVAL '10 minutes')
     AND (p_order_id IS NULL OR id = p_order_id)
  RETURNING *;
$$ LANGUAGE sql SECURITY DEFINER SET search_path = public;

-- ============================================================
-- REPORTS (admin only). Dates are in IST — the DB clock is UTC, so a plain
-- CURRENT_DATE would put 00:00–05:30 IST orders on the previous day.
-- Unpaid/abandoned online orders are excluded from counts.
-- ============================================================
CREATE OR REPLACE FUNCTION get_dashboard_stats()
RETURNS JSON AS $$
DECLARE
  v_today_start TIMESTAMPTZ := date_trunc('day', NOW() AT TIME ZONE 'Asia/Kolkata') AT TIME ZONE 'Asia/Kolkata';
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE = '42501';
  END IF;

  RETURN json_build_object(
    'today_orders',      (SELECT COUNT(*) FROM orders
                           WHERE created_at >= v_today_start
                             AND (payment_method = 'cod' OR payment_status NOT IN ('pending', 'failed'))),
    'today_revenue',     (SELECT COALESCE(SUM(total), 0) FROM orders
                           WHERE payment_status = 'paid' AND paid_at >= v_today_start),
    'pending_orders',    (SELECT COUNT(*) FROM orders
                           WHERE status IN ('placed', 'confirmed', 'preparing')
                             AND (payment_method = 'cod' OR payment_status = 'paid')),
    'active_deliveries', (SELECT COUNT(*) FROM orders WHERE status IN ('ready', 'out_for_delivery')),
    'total_products',    (SELECT COUNT(*) FROM products WHERE is_active = true),
    'low_stock',         (SELECT COUNT(*) FROM products WHERE is_active = true AND stock_quantity > 0 AND stock_quantity <= stock_alert_threshold),
    'out_of_stock',      (SELECT COUNT(*) FROM products WHERE is_active = true AND stock_quantity = 0)
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- Revenue = money actually received (online captured, or COD collected on delivery).
-- Refunded orders drop out automatically (payment_status leaves 'paid').
CREATE OR REPLACE FUNCTION get_earnings(p_period TEXT DEFAULT 'today')
RETURNS JSON AS $$
DECLARE
  v_today_start TIMESTAMPTZ := date_trunc('day', NOW() AT TIME ZONE 'Asia/Kolkata') AT TIME ZONE 'Asia/Kolkata';
  v_start TIMESTAMPTZ;
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE = '42501';
  END IF;

  v_start := v_today_start - CASE p_period
    WHEN 'week'  THEN INTERVAL '6 days'    -- last 7 days incl. today
    WHEN 'month' THEN INTERVAL '29 days'   -- last 30 days incl. today
    ELSE INTERVAL '0'
  END;

  RETURN (
    SELECT json_build_object(
      'total_revenue',   COALESCE(SUM(total), 0),
      'total_orders',    COUNT(*),
      'avg_order_value', COALESCE(AVG(total), 0)::INTEGER,
      'cod_revenue',     COALESCE(SUM(CASE WHEN payment_method = 'cod' THEN total END), 0),
      'online_revenue',  COALESCE(SUM(CASE WHEN payment_method = 'razorpay' THEN total END), 0),
      'orders', (
        SELECT json_agg(row_to_json(t) ORDER BY t.paid_at DESC)
        FROM (
          SELECT order_number, total, payment_method, payment_status, status, created_at, paid_at
          FROM orders WHERE payment_status = 'paid' AND paid_at >= v_start
          ORDER BY paid_at DESC LIMIT 50
        ) t
      )
    )
    FROM orders WHERE payment_status = 'paid' AND paid_at >= v_start
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- NOTE: the old deduct_stock() / restore_stock() functions are intentionally REMOVED.
-- They were callable by any user via /rpc and could zero out or inflate stock at will.
-- Stock now moves only inside place_order() and apply_order_transition().

-- ============================================================
-- EXECUTE PERMISSIONS
-- Supabase grants EXECUTE on every public function to anon + authenticated by default,
-- exposing each one at /rest/v1/rpc/<name>. Lock everything down explicitly.
-- ============================================================

-- Internal: server-side only
REVOKE EXECUTE ON FUNCTION
  place_order(UUID, JSONB, UUID, payment_method, TEXT),
  apply_order_transition(UUID, order_status, UUID, TEXT, UUID, order_status),
  mark_order_paid(TEXT, TEXT, TEXT),
  mark_payment_failed(TEXT),
  expire_unpaid_orders(),
  claim_refunds(UUID),
  cleanup_delivery_locations()
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION
  place_order(UUID, JSONB, UUID, payment_method, TEXT),
  apply_order_transition(UUID, order_status, UUID, TEXT, UUID, order_status),
  mark_order_paid(TEXT, TEXT, TEXT),
  mark_payment_failed(TEXT),
  claim_refunds(UUID)
TO service_role;

-- App-callable: signed-in users only (each function checks permissions itself)
REVOKE EXECUTE ON FUNCTION
  update_order_status(UUID, order_status, TEXT, UUID),
  set_admin_note(UUID, TEXT),
  get_dashboard_stats(),
  get_earnings(TEXT),
  get_latest_delivery_location(UUID)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION
  update_order_status(UUID, order_status, TEXT, UUID),
  set_admin_note(UUID, TEXT),
  get_dashboard_stats(),
  get_earnings(TEXT),
  get_latest_delivery_location(UUID)
TO authenticated;
```

### 011_realtime.sql
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE delivery_locations;
```

### 012_jobs_and_triggers.sql
> Run only after creating the Vault secrets `project_url` and `internal_secret` (see ENVIRONMENT VARIABLES).

```sql
-- Call an internal edge function from the database. pg_net queues the request and
-- sends it after the transaction commits, so it never fires for rolled-back changes.
CREATE OR REPLACE FUNCTION call_internal_function(p_name TEXT, p_body JSONB)
RETURNS void AS $$
BEGIN
  PERFORM net.http_post(
    url     := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'project_url')
               || '/functions/v1/' || p_name,
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'x-internal-secret',
                 (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'internal_secret')
               ),
    body    := p_body
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE EXECUTE ON FUNCTION call_internal_function(TEXT, JSONB) FROM PUBLIC, anon, authenticated;

-- Refund immediately when a paid order becomes refund_pending (cancel / reject / late payment)
CREATE OR REPLACE FUNCTION on_refund_pending()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM call_internal_function('process-refund', jsonb_build_object('order_id', NEW.id));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trg_refund_pending
  AFTER UPDATE OF payment_status ON orders
  FOR EACH ROW
  WHEN (NEW.payment_status = 'refund_pending' AND OLD.payment_status IS DISTINCT FROM 'refund_pending')
  EXECUTE FUNCTION on_refund_pending();

-- Status-change push notifications (Milestone 9) are sent from the server, never the app,
-- so a client can't spoof or spam notifications.
CREATE OR REPLACE FUNCTION on_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM call_internal_function('send-push', jsonb_build_object(
    'type', 'order_status', 'order_id', NEW.id, 'status', NEW.status
  ));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trg_order_status_push
  AFTER UPDATE OF status ON orders
  FOR EACH ROW
  WHEN (NEW.status IS DISTINCT FROM OLD.status)
  EXECUTE FUNCTION on_order_status_change();

-- Scheduled jobs
SELECT cron.schedule('expire-unpaid-orders', '*/5 * * * *',
  $$SELECT public.expire_unpaid_orders()$$);

SELECT cron.schedule('retry-refunds', '*/10 * * * *', $$
  SELECT public.call_internal_function('process-refund', '{}'::jsonb)
  WHERE EXISTS (SELECT 1 FROM public.orders
                WHERE payment_status = 'refund_pending' AND razorpay_refund_id IS NULL)
$$);

SELECT cron.schedule('cleanup-delivery-locations', '0 * * * *',
  $$SELECT public.cleanup_delivery_locations()$$);
```

---

## EDGE FUNCTIONS

> **Common rules for all edge functions**
> - User-facing functions (`create-order`, `verify-payment`) keep JWT verification ON and take `user_id` from the verified JWT (`supabase.auth.getUser()`), **never from the request body**.
> - Internal functions (`razorpay-webhook`, `process-refund`, `send-push`) are deployed with `--no-verify-jwt` and authenticate themselves: Razorpay signature, or the `x-internal-secret` header (= `INTERNAL_FUNCTION_SECRET`).
> - DB writes use a service-role client created inside the function. The service-role key never leaves the server.
> - Signature checks use a constant-time compare (`crypto.subtle.timingSafeEqual` or equivalent), never `===`.

### create-order/index.ts
```
Purpose: Create an order on the server. Prices, stock, totals and fees are decided by the DB — never by the client.

Auth: user JWT required → user_id = verified JWT subject

Input: {
  items: [{ product_id, quantity }],   // Only IDs and quantities — client prices are ignored
  address_id: UUID,
  payment_method: "razorpay" | "cod",
  customer_note?: string
}

Logic:
1. Verify JWT → user_id (401 if missing/invalid)
2. rpc('place_order', { p_user_id, p_items, p_address_id, p_payment_method, p_customer_note })
   In ONE transaction this: checks shop open + method enabled, checks the address belongs to the user,
   reads CURRENT prices, ATOMICALLY RESERVES STOCK (no overselling), enforces min order,
   computes delivery fee + total, inserts the order (stock_reserved=true) + first status-log row.
   Map DB errors → HTTP 409 { code } so the app can show exact messages:
     OUT_OF_STOCK:<product_id> | BELOW_MIN_ORDER | SHOP_CLOSED | COD_DISABLED |
     ONLINE_PAYMENT_DISABLED | ADDRESS_NOT_FOUND | INVALID_QUANTITY | EMPTY_CART
3. If payment_method = "razorpay":
   a. POST https://api.razorpay.com/v1/orders
      { amount: order.total, currency: "INR", receipt: order.id, notes: { order_id: order.id } }
   b. If Razorpay fails → rpc('apply_order_transition', { p_order_id, p_new_status: 'cancelled',
      p_note: 'Payment gateway error' }) (releases the stock) → return 502 { code: 'PAYMENT_GATEWAY_ERROR' }
   c. UPDATE orders SET razorpay_order_id = <rzp id> WHERE id = order.id   (service role)
   d. Return { order_id, order_number, razorpay_order_id, amount, currency, key_id }
   e. Do NOT notify the shop yet — online orders are hidden from the shop until paid.
4. If payment_method = "cod":
   a. Push to admins: "🛒 New Order #{n}" / "{count} items · ₹{total}" (call send-push internally)
   b. Return { order_id, order_number }
```

### verify-payment/index.ts
```
Purpose: FAST PATH payment confirmation right after the Razorpay sheet succeeds.
         (The webhook below is the guaranteed path — this one only makes the UI instant.)

Auth: user JWT required

Input: {
  razorpay_order_id: string,
  razorpay_payment_id: string,
  razorpay_signature: string
}

Logic:
1. Load order by razorpay_order_id → 404 unless order.user_id = caller
2. expected = hex(HMAC_SHA256(razorpay_order_id + "|" + razorpay_payment_id, RAZORPAY_KEY_SECRET))
3. Constant-time compare with razorpay_signature
4. NO MATCH → return 400 { success: false, code: 'SIGNATURE_MISMATCH' }
   Do NOT mark the order failed — a forged/garbled request must not be able to fail a genuine
   payment. The order stays pending; the webhook settles it.
5. MATCH → rpc('mark_order_paid', { p_razorpay_order_id, p_payment_id, p_signature })  (idempotent)
   - result 'paid'              → push admins "🛒 New Order #{n}" → { success: true, order_number }
   - result 'already_processed' → webhook got there first → { success: true, order_number } (no 2nd push)
   - result 'refund_queued'     → order had expired → { success: false, code: 'ORDER_EXPIRED' }
                                  App shows: "Order timed out — your ₹X will be refunded automatically."
```

### razorpay-webhook/index.ts  (NEW — source of truth for payments)
```
Purpose: Settle payments even if the app was killed, lost network, or never called verify-payment
         after the customer paid. Also tracks refund completion.

Deploy:  supabase functions deploy razorpay-webhook --no-verify-jwt
Setup:   Razorpay Dashboard → Settings → Webhooks → Add
           URL:    https://<project>.supabase.co/functions/v1/razorpay-webhook
           Secret: RAZORPAY_WEBHOOK_SECRET
           Events: payment.captured, order.paid, payment.failed, refund.processed, refund.failed
         Razorpay Dashboard → Settings → Payment Capture → Automatic (otherwise payments stay
         "authorized" and Razorpay auto-refunds them after a few days)

Logic:
1. Read the RAW body as text (before JSON.parse — re-serialized JSON breaks the signature)
2. expected = hex(HMAC_SHA256(rawBody, RAZORPAY_WEBHOOK_SECRET)); constant-time compare with the
   X-Razorpay-Signature header → 400 if mismatch
3. Handle event (Razorpay may deliver the same event more than once — every branch is idempotent):
   payment.captured | order.paid:
     rpc('mark_order_paid', { p_razorpay_order_id: payment.order_id, p_payment_id: payment.id })
     result 'paid' → push admins "🛒 New Order #{n}"  (other results: nothing to do)
   payment.failed:
     rpc('mark_payment_failed', { p_razorpay_order_id: payment.order_id })
     (order stays open — the customer can retry; expire_unpaid_orders() cleans up after 20 min)
   refund.processed:
     UPDATE orders SET payment_status='refunded', refunded_at=NOW()
      WHERE razorpay_payment_id = refund.payment_id AND payment_status = 'refund_pending'
     push customer "💸 Refund processed — ₹{amount} is on its way to your account"
   refund.failed:
     UPDATE orders SET razorpay_refund_id = NULL, refund_attempted_at = NULL
      WHERE razorpay_payment_id = refund.payment_id     (process-refund cron retries it)
     push admins "⚠️ Refund failed for order #{n} — will retry"
   any other event → ignore
4. Return 200 for handled/ignored events. Return 500 only on DB errors (so Razorpay retries).
```

### process-refund/index.ts  (NEW)
```
Purpose: Automatically refund paid online orders that were cancelled (customer cancel, shop reject,
         or payment that arrived after the order expired).

Triggered by: (a) DB trigger trg_refund_pending, instantly (012)
              (b) pg_cron 'retry-refunds' every 10 min, as a safety net
Deploy: --no-verify-jwt. Reject with 401 unless header x-internal-secret === INTERNAL_FUNCTION_SECRET.

Input: { order_id?: UUID }    // omitted → process every pending refund

Logic, for each row from rpc('claim_refunds', { p_order_id }):   // atomic claim → no double refunds
1. GET https://api.razorpay.com/v1/payments/{razorpay_payment_id}/refunds
   If a refund already exists (e.g. a previous run crashed after creating it) → save its id, skip to 4
2. POST https://api.razorpay.com/v1/payments/{razorpay_payment_id}/refund
   { amount: order.total, speed: "normal", receipt: order.id, notes: { order_id: order.id } }
3. On API error: leave as is — the claim expires after 10 min and the cron retries
4. UPDATE orders SET razorpay_refund_id = <refund id> WHERE id = order.id
   (payment_status stays 'refund_pending' until the refund.processed webhook → 'refunded')
5. Push customer: "💸 Refund of ₹{total} initiated — 5-7 working days"
```

### send-push/index.ts
```
Purpose: Send push notifications via the Expo Push API. INTERNAL ONLY.

Deploy: --no-verify-jwt. Reject with 401 unless header x-internal-secret === INTERNAL_FUNCTION_SECRET.
        (Otherwise any user could send pushes to the shopkeeper or other customers.)
Callers: other edge functions, and DB trigger trg_order_status_push (012).

Input, one of:
  A) { user_id?: UUID, role?: "admin" | "delivery", title, body, data?: { screen, params } }
  B) { type: "order_status", order_id: UUID, status: order_status }
     → loads the order and builds title/body/recipients from the Milestone 9 table on the server

Logic:
1. Resolve recipients → fetch expo_push_token(s) from profiles where notifications_enabled = true
2. POST https://exp.host/--/api/v2/push/send (batch up to 100 messages per request)
3. Tokens returned as DeviceNotRegistered → set profiles.expo_push_token = NULL
4. Return delivery result
```
---

## MILESTONES

---

### MILESTONE 1: Project Setup & Database
**Goal:** Expo app running, Supabase schema ready, navigation structure working.
**Time:** 2-3 hours

**Steps:**
1. Create Expo project: `npx create-expo-app@latest dukaan-app --template blank-typescript`
2. Install dependencies:
   - Navigation: `expo-router expo-linking expo-constants react-native-safe-area-context react-native-screens react-native-gesture-handler react-native-reanimated`
   - Supabase: `@supabase/supabase-js react-native-url-polyfill expo-secure-store`
   - State: `zustand`
   - UI: `expo-image react-native-svg react-native-toast-message`
3. Configure app.json: scheme "dukaan", package "com.dukaan.app", Google Maps key placeholder
4. Create `lib/supabase.ts` — Supabase client with SecureStore adapter for token persistence
5. Set up Expo Router file structure with all 3 module layouts:
   - `(auth)` — stack navigator
   - `(customer)` — bottom tabs: Home, Cart, Orders, Profile
   - `(admin)` — bottom tabs: Dashboard, Products, Orders, Settings
   - `(delivery)` — stack navigator
   - Placeholder screens with title text for now
6. Root `_layout.tsx`: wrap in AuthProvider, check auth state, redirect by role
7. Run migrations 001–011 in Supabase SQL editor. Migration 012 (cron + DB→edge-function triggers) runs in Milestone 5, after the Vault secrets exist and the edge functions are deployed
8. Create and run seed.sql: 1 shop_config, 6 categories (Grocery, Dairy, Snacks, Beverages, Personal Care, Household), 25 products with realistic Indian shop items and paisa prices, profile entries for 1 admin + 2 customers + 1 delivery person

**Acceptance Tests:**
```
[ ] npx expo start → app opens on phone/emulator
[ ] Splash shows, redirects to login placeholder
[ ] All database tables visible in Supabase with seed data
[ ] Switching role in root layout shows correct tab bar
[ ] Customer: 4 tabs (Home, Cart, Orders, Profile)
[ ] Admin: 4 tabs (Dashboard, Products, Orders, Settings)
[ ] Delivery: single stack screen
```

---

### MILESTONE 2: Phone OTP Auth
**Goal:** Login with phone + OTP, role-based routing.
**Time:** 3-4 hours

**Steps:**
1. Enable Phone Auth in Supabase dashboard (test mode for dev: any 6-digit OTP works)
2. Create `lib/auth.tsx` — AuthProvider context exposing: `user, profile, loading, signInWithOtp(phone), verifyOtp(phone, token), signOut()`
3. Login screen: dark themed, phone input with "+91" prefix locked, "Send OTP" button
4. OTP screen: 6 individual digit TextInputs, auto-advance focus on type, 30-second resend countdown, "Verify" button
5. After first login: if `profile.full_name` is empty → show name prompt modal before proceeding
6. After auth: fetch profile.role → redirect to correct module layout
7. Logout: `supabase.auth.signOut()` → clear local state → return to login

**Acceptance Tests:**
```
[ ] Phone input accepts 10-digit number with +91
[ ] "Send OTP" calls supabase.auth.signInWithOtp
[ ] OTP screen auto-advances through 6 digits
[ ] Correct OTP → logged in, profile exists in profiles table
[ ] Wrong OTP → error message
[ ] First-time user → name prompt
[ ] customer → customer tabs, admin → admin tabs, delivery → delivery screen
[ ] Session persists on app restart
[ ] Logout clears session, returns to login
[ ] Resend works after 30s cooldown
```

---

### MILESTONE 3: Product Catalog (Customer Module)
**Goal:** Browse products, categories, search. This is the core customer experience.
**Time:** 5-6 hours

**Steps:**
1. `useShopConfig` hook: fetch the single shop_config row
2. `useCategories` hook: fetch active categories ordered by sort_order
3. `useProducts` hook: fetch with optional filters (categoryId, search, featured, sort, page/limit)
4. **Home screen:**
   - Shop banner image (shop_config.shop_banner_url) with name overlay
   - Horizontal scrollable CategoryChip components
   - "Featured" section: horizontal FlatList of ProductCards where is_featured=true
   - "All Products" section: 2-column FlatList/FlashList, paginated with onEndReached
5. **ProductCard component:**
   - Product image via expo-image with blurhash placeholder
   - Name (1 line, ellipsis)
   - Price: `₹85` with `~~₹95~~` MRP strikethrough if mrp > price
   - "10% OFF" badge if discounted
   - "Out of Stock" overlay when stock_quantity = 0
   - "ADD" button → on first tap adds 1 to cart and transforms into QuantitySelector
   - If already in cart: show QuantitySelector with current quantity
6. **QuantitySelector component:** `[ - ] 2 [ + ]` — minimum 1 (hitting - at 1 removes from cart), maximum = stock_quantity
7. **Category screen:** header = category name, FlatList of products filtered by category_id, sort dropdown (Price ↑, Price ↓, Name A-Z)
8. **Product Detail screen:**
   - Swipeable image carousel with pagination dots
   - Name, full description
   - Price + MRP + "X% OFF" calculation
   - "Per {unit}" label
   - Stock indicator: green "In Stock" / red "Out of Stock"
   - Large QuantitySelector + "Add to Cart" button
9. **Search screen:**
   - Auto-focus TextInput with search icon
   - Debounced (300ms) query → `search_text ILIKE '%query%'` via Supabase
   - Results as 2-column ProductCard grid
   - Recent searches in AsyncStorage (last 5), shown when input empty
   - Empty state: "Search for dal, rice, soap..."
   - No results: "No products found" with illustration

**Acceptance Tests:**
```
[ ] Home loads shop banner + categories + products from Supabase
[ ] Categories scroll horizontally, tapping one opens filtered view
[ ] ProductCard: image, name, ₹price, ~~MRP~~, discount badge
[ ] Out-of-stock: grey overlay, ADD button disabled
[ ] ADD button → inline +/- quantity selector (no navigation)
[ ] Product detail: image swipes, all fields display
[ ] Search: "dal" finds "Toor Dal" with partial match
[ ] Debounce: rapid typing doesn't fire per-keystroke
[ ] Recent searches saved and displayed
[ ] Pull-to-refresh on home and category screens
[ ] 2-column grid renders properly on phone
[ ] Images load smoothly with placeholder
```

---

### MILESTONE 4: Cart & Checkout (Customer Module)
**Goal:** Cart management, address picker, ready for payment.
**Time:** 4-5 hours

**Steps:**
1. **Cart store** (`lib/cart.ts` — Zustand + AsyncStorage persistence):
   - `items: CartItem[]` (product_id, name, price, mrp, image_url, quantity, max_stock, unit)
   - `addItem(product)` — add with qty 1 or increment (cap at stock)
   - `removeItem(productId)` — remove entirely
   - `setQuantity(productId, qty)` — set exact qty (0 = remove)
   - `clear()` — empty cart
   - `getSubtotal()` — sum(price × quantity) in paisa
   - `getItemCount()` — total quantity across items
2. **CartBadge:** animated count on Cart tab icon (red circle with number)
3. **Cart screen:**
   - FlatList of CartItems: thumbnail, name, unit price, QuantitySelector, line total
   - Swipe-to-delete (react-native-gesture-handler)
   - CartSummary pinned at bottom: Subtotal · Delivery ₹30 (or "FREE") · Total ₹XXX
   - If below min_order_amount: amber banner "Add ₹XX more to place order"
   - Empty state: bag illustration + "Your cart is empty" + "Browse Products" button
   - "Proceed to Checkout →" button (disabled if empty or below minimum)
4. **Checkout screen:**
   - **Address:** show default AddressCard with "Change" link. No addresses: "Add delivery address" CTA
   - **Address picker modal:** radio-select list of saved addresses + "Add New Address" at bottom
   - **Payment method:** radio group: "Pay Online (UPI / Card / Wallet)" and "Cash on Delivery" (shown only if shop_config.cod_enabled)
   - **Customer note:** TextInput "Any instructions for delivery?"
   - **Order summary:** collapsed accordion showing cart items
   - **Place Order — ₹{total}** button at bottom (fixed position)
5. **Add Address screen:**
   - Full address (multiline TextInput)
   - Landmark TextInput
   - Pincode (6-digit, numeric keyboard)
   - "📍 Use Current Location" button: expo-location permission → getCurrentPositionAsync → reverse geocode via Google Maps API → auto-fill address fields
   - Small MapView (200px height) showing pin at coords (draggable to adjust)
   - Label pills: Home / Work / Other
   - "Set as default" toggle
   - Save → insert to addresses table
6. **Manage Addresses screen:**
   - List with label icon, address text, default badge
   - Each: Edit / Delete / Set Default actions

**Acceptance Tests:**
```
[ ] ADD on ProductCard adds to cart, shows QuantitySelector inline
[ ] CartBadge shows count, animates on change
[ ] Cart: items listed with correct prices
[ ] +/- respects max stock (can't exceed stock_quantity)
[ ] Swipe-to-delete removes item
[ ] Subtotal + delivery_fee = total (correct math)
[ ] Delivery = ₹0 when subtotal >= free_delivery_above
[ ] "Add ₹XX more" when below min_order_amount
[ ] Empty cart: illustration + browse button
[ ] Cart persists after app kill + restart
[ ] Checkout: default address shown, Change opens picker
[ ] "Use Current Location" gets GPS → fills address
[ ] Map pin at correct location
[ ] New address saves to Supabase
[ ] Edit/delete/set-default on addresses
[ ] Payment method radio works
[ ] Place Order disabled until address set + minimum met
```

---

### MILESTONE 5: Payments & Order Placement (Customer Module)
**Goal:** Razorpay integration, order creation with server-side validation.
**Time:** 5-6 hours

> **NOTE:** Expo Go won't work from here. You need a development build:
> ```bash
> npx expo install react-native-razorpay
> npx expo prebuild
> npx expo run:android
> ```

**Steps:**
1. Install `react-native-razorpay`, run `npx expo prebuild`
2. Set edge function secrets (RAZORPAY_*, INTERNAL_FUNCTION_SECRET) and create the Vault secrets
3. Deploy Edge Functions (see EDGE FUNCTIONS section above):
   - `create-order`, `verify-payment` (JWT verification ON)
   - `razorpay-webhook`, `process-refund`, `send-push` (`--no-verify-jwt`; they check their own signature/secret)
4. Run migration `012_jobs_and_triggers.sql`
5. Razorpay Dashboard (test mode): add the webhook (URL, secret, 5 events listed under razorpay-webhook) and set Payment Capture → Automatic
6. **App payment flow** (in checkout screen):
   - User taps "Place Order" → disable button immediately (no double-submit) → full-screen loading
   - Call `create-order` edge function with: items (product_id + quantity ONLY), address_id, payment_method, customer_note
   - On 409 error codes show a precise message (e.g. `OUT_OF_STOCK:<id>` → "Only N left of Toor Dal" after refetching that product, and update the cart)
   - **If Razorpay:**
     - Receive razorpay_order_id from edge function
     - Open `RazorpayCheckout.open({ key, amount, currency, order_id, name: shop_name, prefill: { contact: phone }, timeout: 900 })`
       (`timeout: 900` = 15 min, so no payment can complete after the order's 20-min expiry)
     - On success callback: call `verify-payment` with the 3 razorpay values
       - `success: true` → navigate to order-success
       - `ORDER_EXPIRED` → show "Order timed out — your money will be refunded automatically"
       - Network error / `SIGNATURE_MISMATCH` → do NOT show "failed". Navigate to the order detail screen showing
         "Confirming payment…"; the webhook settles it and Realtime updates the screen
     - On dismiss / failure callback: stay on checkout with "Payment not completed" + **Retry Payment**
       (re-opens the sheet with the SAME razorpay_order_id — never create a second order). Unpaid orders
       auto-cancel after 20 min and their stock is released
   - **If COD:**
     - Edge function creates the order (stock already reserved inside place_order) + notifies admin
     - Navigate to order-success
6. **Order Confirmation screen:**
   - Green checkmark animation (Reanimated)
   - "Order #{order_number} Placed!"
   - "Estimated delivery: 30-45 minutes"
   - "Track Order" button → order detail screen
   - "Continue Shopping" → home
   - Clear cart on mount

**Acceptance Tests:**
```
[ ] Place Order calls create-order edge function
[ ] Edge function recalculates prices from DB (client price tampering has no effect)
[ ] Out-of-stock items rejected server-side
[ ] Razorpay sheet opens with correct ₹ amount
[ ] Test card (4111 1111 1111 1111) → payment succeeds
[ ] verify-payment: valid signature → payment_status='paid'
[ ] verify-payment: invalid signature → 400, order stays 'pending' (NOT marked failed)
[ ] Stock is reserved the moment the order is created (check products table), for both COD and online
[ ] Admin gets push: "New Order #42! ₹350" — exactly once, even though verify-payment AND webhook both fire
[ ] COD order creates without Razorpay
[ ] Confirmation screen shows order number
[ ] Cart cleared after success
[ ] Back from confirmation goes to home (not checkout)

SECURITY / RELIABILITY (must all pass):
[ ] Kill the app right after paying (before verify-payment runs) → webhook marks the order 'paid' within seconds
[ ] Webhook with a wrong X-Razorpay-Signature → 400, nothing changes
[ ] Same webhook event delivered twice → no duplicate push, no state change on the 2nd delivery
[ ] Two devices buy the last unit at the same moment → exactly one succeeds, the other gets OUT_OF_STOCK; stock never < 0
[ ] Online order left unpaid > 20 min → auto-cancelled, stock restored
[ ] Payment that completes after the order expired → automatically refunded
[ ] Supabase JS with the customer's session: `from('orders').insert(...)` → rejected by RLS
[ ] `from('orders').update({ total: 1 })` as customer / delivery / admin → rejected (0 rows)
[ ] `from('profiles').update({ role: 'admin' })` on own row as customer → error FORBIDDEN
[ ] `rpc('place_order' | 'apply_order_transition' | 'mark_order_paid' | 'claim_refunds')` from the app → permission denied
[ ] `rpc('get_earnings')` / `rpc('get_dashboard_stats')` as customer → FORBIDDEN
[ ] Calling send-push / process-refund without x-internal-secret → 401
```

---

### MILESTONE 6: Order Management

#### Part A: Customer Order Screens (2-3 hours)

1. **My Orders:** FlatList sorted by created_at DESC
   - OrderCard: "#42 · 3 items · ₹350" with colored status badge
   - Badge colors: placed=blue, confirmed=purple, preparing=amber, ready=orange, out_for_delivery=indigo, delivered=green, cancelled=red
   - Payment sub-badge: online + pending/failed = "Awaiting payment" (with **Retry Payment** while < 15 min old), refund_pending = "Refund in progress", refunded = "Refunded"
2. **Order Detail:**
   - OrderTimeline: vertical line with status dots + timestamps from order_status_log
   - Items list with thumbnails and quantities
   - Price breakdown
   - Delivery address with small map thumbnail
   - "Cancel Order" (only when status='placed'): confirm modal (with reason) → `rpc('update_order_status', { p_order_id, p_new_status: 'cancelled', p_note: reason })`.
     That single call releases stock (once) and, for paid orders, triggers the automatic refund. Do not call anything else.
     If it returns `ORDER_STATUS_CHANGED`, show "The shop has already accepted this order — please call them" + call button
   - "Track Delivery" button (only when status='out_for_delivery')
3. **Realtime:** `useOrderDetail` subscribes via Supabase Realtime — status changes reflect instantly

#### Part B: Shopkeeper Order Management (3-4 hours)

1. **Order List (Admin):**
   - Segmented tabs: New | Active | Delivery | Done | Cancelled
   - New tab: AdminOrderCard with "ACCEPT" (green) + "REJECT" (red) buttons
   - Every tab only shows orders where `payment_method = 'cod' OR payment_status NOT IN ('pending', 'failed')`
     (abandoned/unpaid online checkouts never reach the shop)
   - Realtime subscription: new order → sound + vibrate
   - Pull-to-refresh
2. **Order Detail (Admin):**
   - Customer: name, phone (tap to call via `Linking.openURL('tel:...')`)
   - Items, payment info, customer note
   - Admin note TextInput → saved via `rpc('set_admin_note', { p_order_id, p_note })` (no direct table update)
   - **Contextual status buttons:**
     - `placed` → "Accept" / "Reject" (reason modal; reject auto-restores stock and auto-refunds if paid)
     - `confirmed` → "Start Preparing"
     - `preparing` → "Mark Ready"
     - `ready` → Assign delivery person (dropdown of available) + "Out for Delivery"
     - `out_for_delivery` → show delivery person info + tracking
   - Each action calls `update_order_status()` RPC (assignment: pass `p_delivery_person_id`)
   - Map RPC errors to friendly toasts: `INVALID_TRANSITION` / `ORDER_STATUS_CHANGED` → "Order was updated elsewhere" + refetch,
     `PAYMENT_NOT_CONFIRMED`, `NO_DELIVERY_PERSON` → "Assign a delivery person first"
3. **Dashboard:**
   - StatCards row: Today's Orders, Revenue (₹), Pending, Active Deliveries
   - Low stock alert: "5 items running low" → tappable
   - Out of stock alert: "2 items out of stock"
   - Shop open/closed toggle → updates shop_config.is_open
   - Recent 5 orders
   - Data from `get_dashboard_stats()` RPC

**Acceptance Tests:**
```
[ ] Customer: My Orders lists all orders newest first
[ ] Customer: OrderTimeline shows progression with timestamps
[ ] Customer: Cancel works only on 'placed', stock restored
[ ] Customer: Realtime — admin status change updates screen instantly
[ ] Admin: New orders tab shows placed orders with Accept/Reject
[ ] Admin: Accept → confirmed, Reject → cancelled (reason saved, stock restored)
[ ] Admin: Status buttons are contextual (only valid next-status shown)
[ ] Admin: Assign delivery dropdown shows delivery-role users
[ ] Admin: Dashboard stats match database
[ ] Admin: Sound/vibrate on new order
[ ] Admin: Shop open/close toggle works

SECURITY / RELIABILITY (must all pass):
[ ] Cancel the same order twice (double-tap, or two devices) → second call fails with INVALID_TRANSITION; stock restored exactly once
[ ] Customer cancels a PAID order → payment_status refund_pending → refund visible in Razorpay dashboard → 'refunded' after webhook
[ ] Admin rejects a PAID order → same automatic refund
[ ] Customer calls update_order_status on someone else's order → FORBIDDEN
[ ] Customer tries 'placed' → 'confirmed' on own order → FORBIDDEN
[ ] Customer cancels at the same moment the admin accepts → exactly one wins; no stock or refund mismatch
[ ] Admin cannot move an unpaid online order past 'placed' (PAYMENT_NOT_CONFIRMED)
[ ] Skipping steps (placed → delivered) is rejected (INVALID_TRANSITION)
[ ] Delivered COD order shows up in today's revenue (payment_status becomes 'paid' on delivery)
[ ] Dashboard "today" uses IST — an order at 01:00 IST counts as today
```

---

### MILESTONE 7: Delivery Module
**Goal:** Delivery person sees orders, navigates, shares live location, marks delivered. Customer tracks on map.
**Time:** 5-6 hours

> Install: `npx expo install react-native-maps expo-location` (needs dev build)

**Steps:**

#### Delivery Dashboard (`(delivery)/index.tsx`)
1. FlatList of assigned orders: `delivery_person_id = me AND status IN ('ready', 'out_for_delivery')`
2. DeliveryCard: order #, customer name + phone (tap to call) from the `delivery_address` snapshot (`name`, `phone` — delivery staff can't read customer profiles), address, items count, total
3. Payment badge: "Paid Online" (green) or "COD: Collect ₹XXX" (orange)
4. If ready: "START DELIVERY" button
5. If out_for_delivery: "VIEW" button
6. Realtime subscription for new assignments

#### Delivery Detail (`(delivery)/[id].tsx`)
1. Order items, address, customer phone
2. MapView: shop marker → customer address marker
3. "📍 Navigate" → opens Google Maps: `Linking.openURL('google.navigation:q=${lat},${lng}')`
4. "Start Delivery" (if ready): calls `update_order_status('out_for_delivery')`, starts location tracking
5. Pulsing "📡 Sharing location" indicator

#### Live Location (`lib/location.ts`)
```
startDeliveryTracking(orderId):
  - Request foreground location permission
  - Location.watchPositionAsync({ accuracy: Balanced, distanceInterval: 50, timeInterval: 10000 })
  - Each update: INSERT into delivery_locations
  - Also update profiles.current_latitude/longitude

stopDeliveryTracking():
  - Remove watcher
```

#### Mark Delivered (`(delivery)/confirm/[id].tsx`)
1. Order summary
2. If COD: "💰 Collect ₹{total/100}" with checkbox confirmation
3. "✅ Mark as Delivered" → update_order_status('delivered') + stopDeliveryTracking()
   (for COD this also sets payment_status='paid' on the server, so the cash counts in Earnings)
4. Customer push "Your order has been delivered!" is sent by the DB trigger `trg_order_status_push` — the app does not send it
5. Navigate back to dashboard

#### Customer Tracking (`(customer)/orders/track/[id].tsx`)
1. Full-screen MapView
2. Markers: shop (blue), customer address (green), delivery person (orange, animated)
3. Realtime subscription to delivery_locations table filtered by order_id
4. On each INSERT: animate marker to new position
5. Bottom card: "On the way!" + delivery person name + call button
6. Only accessible when status = 'out_for_delivery'

**Acceptance Tests:**
```
[ ] Delivery: sees only their assigned orders
[ ] "Start Delivery" → status = out_for_delivery
[ ] Location permission requested
[ ] delivery_locations gets rows every ~10 seconds
[ ] Customer: map shows moving delivery marker in realtime
[ ] "Navigate" opens Google Maps
[ ] "Mark Delivered" → stops tracking, status = delivered
[ ] COD: shows amount to collect
[ ] Push notifications on start + delivery
[ ] Tracking screen only shows for out_for_delivery orders
[ ] Call button opens phone dialer

SECURITY (must all pass):
[ ] Delivery person cannot change status of an order not assigned to them → FORBIDDEN
[ ] Delivery person cannot cancel, or set confirmed/preparing/ready → FORBIDDEN
[ ] Inserting a delivery_locations row for an order not assigned to you (or not out_for_delivery) → rejected by RLS
[ ] Customer A cannot read customer B's delivery_locations or call get_latest_delivery_location for B's order (empty result)
```

---

### MILESTONE 8: Product & Category Management (Shopkeeper Panel)
**Goal:** Admin adds/edits products with images, manages categories.
**Time:** 4-5 hours

> Install: `npx expo install expo-image-manipulator expo-image-picker`

**Steps:**

#### Product List (`(admin)/products/index.tsx`)
1. SearchBar at top
2. Category filter dropdown
3. ProductRow: thumbnail (60×60), name, ₹price, stock badge, active switch
4. Tap → edit. FAB "+" → add (id='new')
5. Pull-to-refresh

#### Add/Edit Product (`(admin)/products/[id].tsx`)
1. Form fields: name (required), Hindi name, description, category dropdown, price ₹ (→ paisa), MRP ₹, stock quantity, unit selector, stock alert threshold, featured toggle
2. **Images:** grid of 4 slots. Tap empty = expo-image-picker (camera/gallery). Compress: 800px width, 80% JPEG. Upload to Supabase Storage `product-images/{product_id}/{timestamp}.jpg`. Progress indicator. Tap existing = remove option. First image = primary.
3. Save: validate required fields, upsert product, success toast, navigate back
4. Delete (edit only): soft delete (is_active = false), confirm modal

#### Categories (`(admin)/categories.tsx`)
1. List: image, name (en + hi), product count
2. Add: name, Hindi name, image
3. Edit: tap to rename/change image
4. Delete: only if 0 products (else "Move products first")
5. Reorder: drag handle → update sort_order

#### Storage Setup
- Bucket `product-images`: public, 5MB max, image/* only
- RLS: admin can upload/delete

**Acceptance Tests:**
```
[ ] Product list with search + category filter
[ ] Add product with images end-to-end
[ ] Edit updates correctly
[ ] Image upload to Supabase Storage works
[ ] Compression keeps files under 500KB
[ ] Up to 4 images
[ ] Remove image deletes from storage
[ ] Price ₹ → paisa conversion on save
[ ] Validation: can't save without name + price
[ ] Category CRUD + reorder works
[ ] New product appears on customer home
[ ] Active/inactive toggle works
```

---

### MILESTONE 9: Push Notifications
**Goal:** Order lifecycle alerts for all 3 roles.
**Time:** 3-4 hours

> Install: `npx expo install expo-notifications expo-device expo-constants`

**Steps:**
1. `lib/notifications.ts`: request permission → get Expo push token → save to profiles.expo_push_token
2. `send-push` is already deployed (Milestone 5) and is internal-only — **the app never calls it**
3. Notifications are sent from the server only:
   - "New order" → from `create-order` (COD) or when `mark_order_paid` returns `'paid'` (online)
   - Every status change → DB trigger `trg_order_status_push` (012) → `send-push` with `{ type: 'order_status', order_id, status }`;
     `send-push` builds the message from this table:

| Event | Who Gets Notified | Title | Body |
|-------|-------------------|-------|------|
| Order placed (COD) / paid (online) | Admin(s) | 🛒 New Order #{n} | {count} items · ₹{total} |
| Order confirmed | Customer | ✅ Order Confirmed | Your order #{n} accepted |
| Order rejected / cancelled | Customer | ❌ Order Cancelled | #{n} cancelled: {reason}{paid ? " · Refund initiated" : ""} |
| Customer cancelled | Admin(s) | ❌ Order #{n} Cancelled | Cancelled by customer |
| Unpaid order expired | Customer | ⌛ Payment not completed | #{n} was cancelled. Your cart is still saved |
| Refund processed | Customer | 💸 Refund Processed | ₹{total} for #{n} is on its way |
| Preparing | Customer | 👨‍🍳 Being Prepared | #{n} is being packed |
| Ready | Customer + Delivery | 📦 Ready | #{n} ready for pickup |
| Out for delivery | Customer | 🛵 On the Way! | #{n} out for delivery |
| Delivered | Customer | ✅ Delivered! | #{n} delivered |

4. Deep linking: notification data `{ screen, params }` → navigate on tap
5. Foreground: show in-app toast via react-native-toast-message

**Acceptance Tests:**
```
[ ] Push token saved to profile
[ ] Admin notified on new order
[ ] Customer notified on every status change
[ ] Delivery notified when order ready
[ ] Tap notification → correct order screen
[ ] Foreground → in-app toast (not system notification)
[ ] Exactly one "New Order" push per order (verify-payment + webhook race does not duplicate)
[ ] App code contains no call to send-push; calling it without x-internal-secret → 401
```

---

### MILESTONE 10: Earnings, Settings & Polish (Shopkeeper Panel)
**Goal:** Revenue tracking, shop config, overall quality.
**Time:** 4-5 hours

**Steps:**

#### Earnings (`(admin)/earnings.tsx`)
1. Tabs: Today / This Week / This Month
2. StatCards: Revenue, Orders, Avg Order Value
3. Online vs COD split
4. Transaction list: date, order #, ₹amount, method, status
5. Data from `get_earnings(period)` RPC

#### Shop Settings (`(admin)/settings.tsx`)
1. Shop name, tagline, logo upload, banner upload
2. Phone, WhatsApp
3. Address + map pin picker (lat/lng)
4. Opening/closing time pickers
5. Delivery fee ₹, free delivery above ₹, min order ₹, radius km
6. COD toggle, Razorpay toggle
7. Save button

#### Delivery Staff (`(admin)/delivery-staff.tsx`)
1. List: name, phone, availability dot
2. Add: enter phone → if account exists set role='delivery', else "Ask them to sign up first"
   (works via the `admin_updates_profiles` policy; `trg_protect_profile_columns` blocks non-admins from changing roles)
3. Remove: set role='customer'. Block removal while they have orders in `ready` / `out_for_delivery` — reassign first

#### Customer Profile (`(customer)/profile.tsx`)
1. Name (editable), phone (readonly)
2. My Addresses link
3. Notification toggle
4. Help → `https://wa.me/{shop_whatsapp}`
5. Logout (with confirmation)

#### UI Polish (all screens)
1. Loading Skeletons on every data screen
2. Error states with retry button
3. Empty states with illustrations + CTAs
4. Pull-to-refresh everywhere
5. Haptic feedback: add to cart, place order, status change (`expo-haptics`)
6. KeyboardAvoidingView on forms
7. Light status bar on dark backgrounds
8. Animations: cart badge bounce, confirmation checkmark (Reanimated)
9. Sentry: `npx expo install @sentry/react-native` → crash tracking
10. Offline banner: `expo-network` → "You're offline" strip

**Acceptance Tests:**
```
[ ] Earnings: correct revenue for today/week/month
[ ] Earnings: transaction list with payment methods
[ ] Settings: shop name change → customer home updates
[ ] Settings: delivery fee change → checkout updates
[ ] Settings: logo/banner upload works
[ ] Delivery staff: add/remove works
[ ] Profile: edit name, help opens WhatsApp, logout works
[ ] All screens: loading skeletons (no white flashes)
[ ] All screens: error state with retry
[ ] Empty states have illustrations
[ ] Haptics fire on key actions
[ ] Sentry receives test crash
[ ] Offline banner on network loss
```

---

### MILESTONE 11: Build & Deploy
**Goal:** Production APK on Google Play Store.
**Time:** 3-4 hours

**Steps:**
1. Configure `eas.json`:
   ```json
   {
     "build": {
       "development": { "developmentClient": true, "distribution": "internal" },
       "preview": { "distribution": "internal", "android": { "buildType": "apk" } },
       "production": { "android": { "buildType": "app-bundle" } }
     }
   }
   ```
2. Create production Supabase project (separate from dev): create Vault secrets (`project_url`, `internal_secret` — new random value),
   set edge function secrets, deploy all 5 edge functions, run all 12 migrations
3. Set production secrets in EAS:
   ```bash
   eas secret:create --name EXPO_PUBLIC_SUPABASE_URL --value "https://prod.supabase.co"
   eas secret:create --name EXPO_PUBLIC_SUPABASE_ANON_KEY --value "eyJ..."
   eas secret:create --name EXPO_PUBLIC_RAZORPAY_KEY_ID --value "rzp_live_xxx"
   eas secret:create --name EXPO_PUBLIC_GOOGLE_MAPS_API_KEY --value "AIza..."
   ```
4. Switch Razorpay to live mode: live keys in edge function secrets, create a **separate live-mode webhook**
   (same URL on the prod project, new RAZORPAY_WEBHOOK_SECRET, same 5 events), confirm Payment Capture = Automatic
5. Configure real SMS OTP in Supabase (Twilio)
6. Build preview APK: `eas build --platform android --profile preview`
7. Install on shopkeeper's phone → test full flow with ₹1 real payment (temporarily set min order ₹1 / delivery fee ₹0 in Settings — the server enforces them), then cancel it and confirm the ₹1 is refunded automatically
8. Build production AAB: `eas build --platform android --profile production`
9. Submit to Play Store:
   - Developer account (₹2,100 one-time — bill to client)
   - Screenshots, description (Hindi + English), content rating, privacy policy
   - Upload AAB
10. Set up OTA updates: `eas update --branch production --message "Fix"`

**Acceptance Tests:**
```
[ ] Preview APK runs on physical device
[ ] Full flow works on production Supabase
[ ] Razorpay live payment (₹1 test)
[ ] Real SMS OTP arrives
[ ] Push notifications work
[ ] Maps load
[ ] All 3 modules functional
[ ] AAB builds clean
[ ] Play Store accepts submission
[ ] OTA update reaches installed app
```

---

### MILESTONE 12: Client Handover
**Goal:** Shopkeeper trained, maintenance started.
**Time:** 2-3 hours

1. Install on shopkeeper's + delivery person's phones
2. Create admin + delivery accounts
3. Train shopkeeper: adding products, managing orders (accept → prepare → ready → assign → deliver), earnings, settings
4. Train delivery: seeing orders, starting delivery, navigating, marking delivered, COD
5. Record 5-min screencast tutorial (optional)
6. Provide printed/PDF cheat sheet
7. Set up maintenance: ₹2,000-3,000/month for monitoring, bug fixes, Play Store updates, WhatsApp support

---

## COST SUMMARY

### What to Charge

| Scope | Price | Time |
|-------|-------|------|
| MVP (no live tracking) — M1-6, 8-11 | ₹30,000–40,000 | 2-3 weeks |
| Full (with live tracking) — all 12 | ₹45,000–60,000 | 3-4 weeks |
| Monthly maintenance | ₹2,000–3,000/month | Ongoing |

### Client's Running Cost

| Service | Cost |
|---------|------|
| Supabase | ₹0 (500MB DB, 1GB storage, 50K MAU free) |
| Razorpay | 2% per transaction (no monthly fee) |
| Google Maps | ₹0 ($200 free credit/month) |
| Expo EAS | ₹0 (30 builds/month free) |
| Twilio SMS OTP | ~₹300-500/month |
| Play Store | ₹2,100 one-time |
| **Total** | **~₹500/month + 2% on transactions** |

---

## HOW TO USE WITH CLAUDE CODE

```
1. Open Claude Code in the project directory
2. Paste this entire PRD
3. Say: "Follow the DukaanApp PRD. Start with Milestone 1.
         Complete all steps and acceptance tests before moving on."
4. Test each milestone on your phone
5. When done: "Milestone X complete. Proceed to Milestone X+1."
```

**Important:**
- **Milestones 1-4:** Work in Expo Go (no native modules)
- **Milestone 5+:** Need dev build (`npx expo prebuild` + `npx expo run:android`)
- **Always test on a real Android phone** for payments, GPS, push notifications

**Do NOT skip milestones. Each one builds on the previous.**
