-- DukaanApp development seed. Run AFTER migrations 001–011, in the Supabase SQL editor.
-- Money is in paisa. Safe to re-run (skips data that already exists).
--
-- TEST LOGINS (add these in Dashboard → Authentication → Providers → Phone →
-- "Test phone numbers and OTPs", e.g. 919999900001=123456 — no SMS is sent):
--   +91 99999 00001  Shopkeeper (admin)
--   +91 99999 00002  Customer — Priya Sharma
--   +91 99999 00003  Customer — Rahul Verma
--   +91 99999 00004  Delivery — Suresh Kumar

-- ─── Shop ────────────────────────────────────────────────────────────────────
UPDATE shop_config SET
  shop_name = 'Krishna General Store',
  shop_tagline = 'Daily essentials, delivered in 30 minutes',
  phone = '+919999900001',
  whatsapp = '919999900001',
  address = 'Shop 12, Main Market, Raja Park, Jaipur 302004',
  latitude = 26.8914,
  longitude = 75.8264,
  delivery_fee = 3000,
  free_delivery_above = 50000,
  min_order_amount = 10000,
  delivery_radius_km = 5.0,
  updated_at = NOW()
WHERE id = 1;

-- ─── Categories ──────────────────────────────────────────────────────────────
INSERT INTO categories (id, name, name_hi, sort_order) VALUES
  ('c0000000-0000-4000-8000-000000000001', 'Grocery',       'किराना',          1),
  ('c0000000-0000-4000-8000-000000000002', 'Dairy',         'डेयरी',           2),
  ('c0000000-0000-4000-8000-000000000003', 'Snacks',        'स्नैक्स',          3),
  ('c0000000-0000-4000-8000-000000000004', 'Beverages',     'पेय पदार्थ',       4),
  ('c0000000-0000-4000-8000-000000000005', 'Personal Care', 'व्यक्तिगत देखभाल',  5),
  ('c0000000-0000-4000-8000-000000000006', 'Household',     'घरेलू सामान',      6)
ON CONFLICT (id) DO NOTHING;

-- ─── Products (25) ───────────────────────────────────────────────────────────
-- Includes deliberate edge cases: 2 low-stock items and 1 out-of-stock item.
INSERT INTO products
  (category_id, name, name_hi, description, price, mrp, stock_quantity, unit, is_featured, sort_order)
SELECT p.category_id::uuid, p.name, p.name_hi, p.description, p.price, p.mrp, p.stock, p.unit, p.featured, p.sort_order
FROM (VALUES
  -- Grocery
  ('c0000000-0000-4000-8000-000000000001', 'Toor Dal 1kg',               'तूर दाल 1 किलो',          'Unpolished arhar dal, rich in protein.',            16500, 18000, 40, 'kg',     true,  1),
  ('c0000000-0000-4000-8000-000000000001', 'Basmati Rice 1kg',           'बासमती चावल 1 किलो',       'Long-grain aged basmati, perfect for biryani.',     12000, 14000, 35, 'kg',     false, 2),
  ('c0000000-0000-4000-8000-000000000001', 'Aashirvaad Whole Wheat Atta 5kg', 'आशीर्वाद आटा 5 किलो', '100% whole wheat chakki atta for soft rotis.',      28500, 30500, 25, 'packet', true,  3),
  ('c0000000-0000-4000-8000-000000000001', 'Tata Salt 1kg',              'टाटा नमक 1 किलो',          'Vacuum evaporated iodised salt.',                    2800,  2800, 60, 'packet', false, 4),
  ('c0000000-0000-4000-8000-000000000001', 'Sugar 1kg',                  'चीनी 1 किलो',             'Refined white sulphur-free sugar.',                  4800,  5000, 50, 'kg',     false, 5),
  ('c0000000-0000-4000-8000-000000000001', 'Fortune Sunflower Oil 1L',   'फॉर्च्यून सूरजमुखी तेल 1 लीटर', 'Light, healthy refined sunflower oil.',         16500, 18500, 30, 'litre',  false, 6),
  -- Dairy
  ('c0000000-0000-4000-8000-000000000002', 'Amul Taaza Toned Milk 500ml','अमूल ताज़ा दूध 500 मिली',   'Pasteurised toned milk, delivered fresh daily.',     2800,  2800, 80, 'packet', true,  1),
  ('c0000000-0000-4000-8000-000000000002', 'Amul Butter 100g',           'अमूल मक्खन 100 ग्राम',     'Pasteurised salted butter.',                          6000,  6200, 30, 'packet', false, 2),
  ('c0000000-0000-4000-8000-000000000002', 'Fresh Paneer 200g',          'ताज़ा पनीर 200 ग्राम',     'Soft malai paneer made from full-cream milk.',        9000,  9500, 20, 'packet', false, 3),
  ('c0000000-0000-4000-8000-000000000002', 'Dahi 400g',                  'दही 400 ग्राम',           'Thick, creamy set curd.',                             4000,  4500, 25, 'packet', false, 4),
  -- Snacks
  ('c0000000-0000-4000-8000-000000000003', 'Lay''s Classic Salted 52g',  'लेज़ क्लासिक नमकीन 52 ग्राम', 'Crispy potato chips with a pinch of salt.',        2000,  2000, 70, 'packet', false, 1),
  ('c0000000-0000-4000-8000-000000000003', 'Haldiram''s Aloo Bhujia 400g','हल्दीराम आलू भुजिया 400 ग्राम', 'Classic spicy potato and besan sev.',          11000, 12000, 30, 'packet', true,  2),
  ('c0000000-0000-4000-8000-000000000003', 'Parle-G Biscuits 800g',      'पारले-जी बिस्किट 800 ग्राम', 'Glucose biscuits — the family favourite.',          9000,  9500,  3, 'packet', false, 3),
  ('c0000000-0000-4000-8000-000000000003', 'Britannia Good Day Cashew 200g','ब्रिटानिया गुड डे काजू 200 ग्राम', 'Buttery cookies loaded with cashew.',      4000,  4000,  0, 'packet', false, 4),
  -- Beverages
  ('c0000000-0000-4000-8000-000000000004', 'Tata Tea Gold 500g',         'टाटा टी गोल्ड 500 ग्राम',  'Assam tea blended with long leaves for rich aroma.', 29000, 32000, 20, 'packet', true,  1),
  ('c0000000-0000-4000-8000-000000000004', 'Nescafé Classic Coffee 50g', 'नेस्कैफे क्लासिक कॉफी 50 ग्राम', '100% pure instant coffee.',                  19000, 20500, 15, 'box',    false, 2),
  ('c0000000-0000-4000-8000-000000000004', 'Coca-Cola 750ml',            'कोका-कोला 750 मिली',       'Chilled soft drink.',                                 4000,  4000, 40, 'piece',  false, 3),
  ('c0000000-0000-4000-8000-000000000004', 'Real Mixed Fruit Juice 1L',  'रियल मिक्स फ्रूट जूस 1 लीटर', 'No added preservatives.',                        12000, 13000, 18, 'litre',  false, 4),
  -- Personal Care
  ('c0000000-0000-4000-8000-000000000005', 'Dettol Original Soap (4 × 75g)', 'डेटॉल साबुन (4 × 75 ग्राम)', 'Germ protection bathing bar, value pack.',      19900, 22000, 25, 'packet', false, 1),
  ('c0000000-0000-4000-8000-000000000005', 'Colgate Strong Teeth 200g',  'कोलगेट स्ट्रॉन्ग टीथ 200 ग्राम', 'Calcium-boost toothpaste.',                   11500, 12500, 30, 'piece',  false, 2),
  ('c0000000-0000-4000-8000-000000000005', 'Clinic Plus Shampoo 340ml',  'क्लिनिक प्लस शैम्पू 340 मिली', 'Strong & long health shampoo.',                21000, 23500, 12, 'piece',  false, 3),
  ('c0000000-0000-4000-8000-000000000005', 'Dove Cream Beauty Bar 100g', 'डव क्रीम ब्यूटी बार 100 ग्राम', '¼ moisturising cream for soft skin.',           5500,  6000,  4, 'piece',  false, 4),
  -- Household
  ('c0000000-0000-4000-8000-000000000006', 'Surf Excel Easy Wash 1kg',   'सर्फ एक्सेल ईज़ी वॉश 1 किलो', 'Detergent powder that removes tough stains.',    14000, 15500, 20, 'packet', false, 1),
  ('c0000000-0000-4000-8000-000000000006', 'Vim Dishwash Bar (3 × 200g)','विम बर्तन बार (3 × 200 ग्राम)', 'Lemon-powered grease cutting.',                 6000,  6500, 35, 'packet', false, 2),
  ('c0000000-0000-4000-8000-000000000006', 'Harpic Toilet Cleaner 500ml','हार्पिक टॉयलेट क्लीनर 500 मिली', 'Kills 99.9% germs.',                          9900, 10500, 22, 'piece',  false, 3)
) AS p(category_id, name, name_hi, description, price, mrp, stock, unit, featured, sort_order)
WHERE NOT EXISTS (SELECT 1 FROM products);

-- ─── Test users (DEV ONLY — never run on production) ────────────────────────
-- Creates phone-auth users directly; the on_auth_user_created trigger makes their profiles.
-- Token columns must be '' (not NULL) or Supabase Auth fails to load the user.
INSERT INTO auth.users (
  instance_id, id, aud, role, phone, phone_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change,
  email_change_token_current, phone_change, phone_change_token, reauthentication_token
)
SELECT
  '00000000-0000-0000-0000-000000000000', u.id::uuid, 'authenticated', 'authenticated', u.phone, NOW(),
  '{"provider":"phone","providers":["phone"]}'::jsonb,
  jsonb_build_object('full_name', u.full_name), NOW(), NOW(),
  '', '', '', '', '', '', '', ''
FROM (VALUES
  ('a0000000-0000-4000-8000-000000000001', '919999900001', 'Krishna Gupta'),
  ('a0000000-0000-4000-8000-000000000002', '919999900002', 'Priya Sharma'),
  ('a0000000-0000-4000-8000-000000000003', '919999900003', 'Rahul Verma'),
  ('a0000000-0000-4000-8000-000000000004', '919999900004', 'Suresh Kumar')
) AS u(id, phone, full_name)
ON CONFLICT (id) DO NOTHING;

INSERT INTO auth.identities (id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
SELECT gen_random_uuid(), u.id::text, u.id,
       jsonb_build_object('sub', u.id::text, 'phone', u.phone, 'phone_verified', true),
       'phone', NOW(), NOW(), NOW()
FROM auth.users u
WHERE u.id IN (
  'a0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000002',
  'a0000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000004'
)
ON CONFLICT (provider_id, provider) DO NOTHING;

-- Roles (runs as postgres, so trg_protect_profile_columns allows it)
UPDATE profiles SET role = 'admin'    WHERE id = 'a0000000-0000-4000-8000-000000000001';
UPDATE profiles SET role = 'delivery' WHERE id = 'a0000000-0000-4000-8000-000000000004';

-- A saved address for the first test customer
INSERT INTO addresses (user_id, label, full_address, landmark, city, pincode, latitude, longitude, is_default)
SELECT 'a0000000-0000-4000-8000-000000000002', 'Home', 'C-45, Tilak Nagar', 'Near Tilak Nagar Park',
       'Jaipur', '302004', 26.8889, 75.8236, true
WHERE NOT EXISTS (SELECT 1 FROM addresses WHERE user_id = 'a0000000-0000-4000-8000-000000000002');
