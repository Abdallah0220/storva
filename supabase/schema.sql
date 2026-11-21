-- ═══════════════════════════════════════════════════════════════
--  Storva - Supabase setup script
--  Run this ONCE in your Supabase project: SQL Editor → New query →
--  paste → Run. It creates every table, security policy, function
--  and the storage bucket the app needs, plus sample data.
-- ═══════════════════════════════════════════════════════════════

-- ── Tables ─────────────────────────────────────────────────────

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  price numeric(10,2) not null check (price >= 0),
  compare_at_price numeric(10,2) check (compare_at_price is null or compare_at_price >= 0),
  category text not null default 'General',
  image_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null,
  phone text not null,
  region text not null,
  city text not null,
  address text not null,
  subtotal numeric(10,2) not null default 0,
  discount_amount numeric(10,2) not null default 0,
  shipping_cost numeric(10,2) not null default 0,
  coupon_code text,
  total numeric(10,2) not null,
  status text not null default 'new'
    check (status in ('new', 'confirmed', 'shipped', 'delivered', 'cancelled')),
  created_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  price numeric(10,2) not null,
  quantity int not null check (quantity > 0)
);

create table if not exists public.coupons (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  discount_percent numeric(5,2) not null check (discount_percent > 0 and discount_percent <= 100),
  is_used boolean not null default false,
  created_at timestamptz not null default now(),
  used_at timestamptz
);

create table if not exists public.shipping_rates (
  id uuid primary key default gen_random_uuid(),
  region text not null unique,
  shipping_cost numeric(10,2) not null default 0 check (shipping_cost >= 0),
  is_active boolean not null default true
);

-- ── Row Level Security ─────────────────────────────────────────
-- anon = store visitors, authenticated = you (the admin login).
-- Admin users are created in Supabase → Authentication → Users.

alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.coupons enable row level security;
alter table public.shipping_rates enable row level security;

-- Products: visitors see only active products; admin manages all.
create policy "public read active products"
  on public.products for select to anon
  using (is_active = true);
create policy "admin full access products"
  on public.products for all to authenticated
  using (true) with check (true);

-- Shipping rates: visitors read active ones; admin manages all.
create policy "public read active rates"
  on public.shipping_rates for select to anon
  using (is_active = true);
create policy "admin full access rates"
  on public.shipping_rates for all to authenticated
  using (true) with check (true);

-- Orders + items: visitors CANNOT read or write them directly.
-- Orders are created only through the create_order_with_items()
-- function below (it runs with elevated rights and recomputes
-- every price server-side). Admin reads/updates them.
create policy "admin read orders"
  on public.orders for select to authenticated using (true);
create policy "admin update orders"
  on public.orders for update to authenticated
  using (true) with check (true);

create policy "admin read order items"
  on public.order_items for select to authenticated using (true);

-- Coupons: never exposed to visitors. Validation and redemption
-- happen inside the functions below. Admin manages them.
create policy "admin full access coupons"
  on public.coupons for all to authenticated
  using (true) with check (true);

-- ── Functions ──────────────────────────────────────────────────

-- Validate a coupon at checkout. Returns one row:
--   is_valid, discount_percent
create or replace function public.validate_coupon(p_code text)
returns table (is_valid boolean, discount_percent numeric)
language plpgsql security definer
set search_path = public
as $$
begin
  return query
    select true, c.discount_percent
    from public.coupons c
    where upper(c.code) = upper(trim(p_code)) and c.is_used = false
    limit 1;

  if not found then
    return query select false, null::numeric;
  end if;
end;
$$;

-- Create an order with its items atomically.
-- The client sends only product ids + quantities; prices, discount,
-- shipping and totals are all recomputed here from the database,
-- so a tampered client cannot change what it pays.
create or replace function public.create_order_with_items(
  p_customer_name text,
  p_phone text,
  p_region text,
  p_city text,
  p_address text,
  p_items jsonb,           -- [{"product_id": "...", "quantity": n}]
  p_coupon_code text default null
)
returns uuid
language plpgsql security definer
set search_path = public
as $$
declare
  v_order_id uuid;
  v_subtotal numeric(10,2) := 0;
  v_discount numeric(10,2) := 0;
  v_shipping numeric(10,2) := 0;
  v_percent numeric(5,2);
  v_item jsonb;
  v_product record;
begin
  -- Validate items and compute subtotal from real DB prices.
  for v_item in select * from jsonb_array_elements(p_items)
  loop
    select id, name, price into v_product
    from public.products
    where id = (v_item->>'product_id')::uuid and is_active = true;

    if not found then
      raise exception 'Product % is not available', v_item->>'product_id';
    end if;

    v_subtotal := v_subtotal
      + v_product.price * greatest((v_item->>'quantity')::int, 1);
  end loop;

  -- Shipping from the region's active rate.
  select coalesce(r.shipping_cost, 0) into v_shipping
  from public.shipping_rates r
  where r.region = p_region and r.is_active = true;
  v_shipping := coalesce(v_shipping, 0);

  -- Coupon: validate and mark used so it can't be reused.
  if p_coupon_code is not null and trim(p_coupon_code) <> '' then
    select c.discount_percent into v_percent
    from public.coupons c
    where upper(c.code) = upper(trim(p_coupon_code)) and c.is_used = false;

    if found then
      v_discount := round(v_subtotal * v_percent / 100, 2);
      update public.coupons
      set is_used = true, used_at = now()
      where upper(coupons.code) = upper(trim(p_coupon_code));
    end if;
  end if;

  insert into public.orders (
    customer_name, phone, region, city, address,
    subtotal, discount_amount, shipping_cost, coupon_code, total, status
  ) values (
    p_customer_name, p_phone, p_region, p_city, p_address,
    v_subtotal, v_discount, v_shipping,
    nullif(trim(p_coupon_code), ''),
    v_subtotal - v_discount + v_shipping,
    'new'
  ) returning id into v_order_id;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    insert into public.order_items (order_id, product_id, product_name, price, quantity)
    select v_order_id, p.id, p.name, p.price,
           greatest((v_item->>'quantity')::int, 1)
    from public.products p
    where p.id = (v_item->>'product_id')::uuid;
  end loop;

  return v_order_id;
end;
$$;

-- Generate a unique single-use coupon (called from the admin panel).
create or replace function public.generate_coupon(p_discount_percent numeric)
returns public.coupons
language plpgsql security definer
set search_path = public
as $$
declare
  v_code text;
  v_row public.coupons;
begin
  if p_discount_percent <= 0 or p_discount_percent > 100 then
    raise exception 'Discount must be between 1 and 100';
  end if;

  loop
    v_code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
    begin
      insert into public.coupons (code, discount_percent)
      values (v_code, p_discount_percent)
      returning * into v_row;
      return v_row;
    exception when unique_violation then
      -- code collision, try again
    end;
  end loop;
end;
$$;

-- Allow visitors to call the storefront functions.
grant execute on function public.validate_coupon(text) to anon;
grant execute on function public.create_order_with_items(text, text, text, text, text, jsonb, text) to anon;
grant execute on function public.generate_coupon(numeric) to authenticated;

-- ── Storage bucket for product images ──────────────────────────

insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

create policy "public read product images"
  on storage.objects for select to anon
  using (bucket_id = 'product-images');
create policy "admin upload product images"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'product-images');
create policy "admin delete product images"
  on storage.objects for delete to authenticated
  using (bucket_id = 'product-images');

-- ── Sample data (edit or delete freely) ────────────────────────

insert into public.shipping_rates (region, shipping_cost) values
  ('Cairo', 40),
  ('Giza', 45),
  ('Alexandria', 60),
  ('Other regions', 80)
on conflict (region) do nothing;

insert into public.products (name, description, price, compare_at_price, category, is_active) values
  ('Aurora Wireless Headphones', 'Over-ear wireless headphones with active noise cancellation and 40-hour battery life.', 129.99, 179.99, 'Electronics', true),
  ('Pulse Smart Watch', 'Fitness smart watch with heart-rate tracking, GPS and an always-on display.', 199.00, null, 'Electronics', true),
  ('Lumen Desk Lamp', 'Minimal desk lamp with three warmth levels and a USB-C charging base.', 45.50, 59.00, 'Home', true)
on conflict do nothing;

insert into public.coupons (code, discount_percent) values
  ('WELCOME10', 10)
on conflict (code) do nothing;

-- ── Last step (manual): create your admin login ────────────────
-- Supabase dashboard → Authentication → Users → Add user →
-- email + password. That account signs in at your-store.com/#/admin
-- and gets full access through the policies above.
