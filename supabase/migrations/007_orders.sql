-- 007_orders.sql — generated from DukaanApp_PRD.md (keep both in sync)

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
