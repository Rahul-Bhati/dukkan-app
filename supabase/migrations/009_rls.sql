-- 009_rls.sql — generated from DukaanApp_PRD.md (keep both in sync)

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
