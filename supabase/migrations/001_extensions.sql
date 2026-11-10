-- 001_extensions.sql — generated from DukaanApp_PRD.md (keep both in sync)

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;  -- scheduled jobs (order expiry, refund retry)
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;   -- DB → edge function HTTP calls
