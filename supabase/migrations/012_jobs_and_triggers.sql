-- 012_jobs_and_triggers.sql — generated from DukaanApp_PRD.md (keep both in sync)

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
