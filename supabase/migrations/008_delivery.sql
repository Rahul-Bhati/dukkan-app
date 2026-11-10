-- 008_delivery.sql — generated from DukaanApp_PRD.md (keep both in sync)

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
