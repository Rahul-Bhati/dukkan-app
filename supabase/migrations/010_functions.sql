-- 010_functions.sql — generated from DukaanApp_PRD.md (keep both in sync)

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
