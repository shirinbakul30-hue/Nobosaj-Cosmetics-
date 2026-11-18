-- Nobosaj Cosmetics: Supabase schema + Row Level Security
-- Run in Supabase SQL Editor. Never put the service_role key in the website.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role text not null default 'customer' check (role in ('customer','admin','factory')),
  created_at timestamptz not null default now()
);
create table if not exists public.store_settings (
  id integer primary key default 1 check (id = 1),
  store_name text not null default 'Nobosaj',
  tagline text not null default 'COSMETICS · নবসাজ',
  address text not null default '',
  phone text not null default '',
  whatsapp text not null default '',
  hero_title text not null default 'নবসাজের সঙ্গে সৌন্দর্য ও যত্ন',
  hero_text text not null default 'প্রতিদিনের স্কিনকেয়ার ও বিউটি পণ্যের সুন্দর সংগ্রহ। পণ্য দেখুন, অর্ডার করুন, মতামত জানান।',
  footer_text text not null default 'সৌন্দর্য ও যত্নে আপনার বিশ্বস্ত ঠিকানা',
  logo_url text not null default '',
  updated_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null default 'Skincare',
  description text,
  price numeric(12,2) not null check (price >= 0),
  stock integer not null default 0 check (stock >= 0),
  image_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  customer_name text not null,
  rating integer not null check (rating between 1 and 5),
  comment text not null,
  is_public boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  customer_name text not null,
  phone text not null,
  address text not null,
  payment_method text not null check (payment_method in ('cod','online')),
  total numeric(12,2) not null check (total >= 0),
  items jsonb not null default '[]'::jsonb,
  status text not null default 'pending' check (status in ('pending','confirmed','processing','shipped','delivered','cancelled')),
  created_at timestamptz not null default now()
);

-- Create a profile automatically; new signups can NEVER self-assign admin/factory.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id, full_name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''), 'customer')
  on conflict (id) do nothing;
  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.store_settings enable row level security;
alter table public.products enable row level security;
alter table public.reviews enable row level security;
alter table public.orders enable row level security;

create or replace function public.current_role()
returns text language sql stable security definer set search_path=public as $$
  select role from public.profiles where id = auth.uid()
$$;

-- Profiles: a user can read their own profile; only admins can manage role assignments.
drop policy if exists "profile self read" on public.profiles;
create policy "profile self read" on public.profiles for select to authenticated
using (id = auth.uid() or public.current_role() = 'admin');
drop policy if exists "admin profile update" on public.profiles;
create policy "admin profile update" on public.profiles for update to authenticated
using (public.current_role() = 'admin') with check (public.current_role() = 'admin');

-- Store identity is public to read; only admins can change it.
drop policy if exists "public read store settings" on public.store_settings;
create policy "public read store settings" on public.store_settings for select using (true);
drop policy if exists "admin insert store settings" on public.store_settings;
create policy "admin insert store settings" on public.store_settings for insert to authenticated
with check (public.current_role() = 'admin');
drop policy if exists "admin update store settings" on public.store_settings;
create policy "admin update store settings" on public.store_settings for update to authenticated
using (public.current_role() = 'admin') with check (public.current_role() = 'admin');

-- Products are public to browse. Only admins can create, edit, and delete products.
-- Factory staff can view stock in this starter; stock adjustments should use a separate audited RPC/workflow.
drop policy if exists "public active products" on public.products;
create policy "public active products" on public.products for select
using (is_active = true or public.current_role() in ('admin','factory'));
drop policy if exists "admin product insert" on public.products;
create policy "admin product insert" on public.products for insert to authenticated
with check (public.current_role() = 'admin');
drop policy if exists "admin product update" on public.products;
create policy "admin product update" on public.products for update to authenticated
using (public.current_role() = 'admin') with check (public.current_role() = 'admin');
drop policy if exists "admin product delete" on public.products;
create policy "admin product delete" on public.products for delete to authenticated
using (public.current_role() = 'admin');

-- Anyone may submit a review; public can read public reviews; admin can read/manage all.
drop policy if exists "public read reviews" on public.reviews;
create policy "public read reviews" on public.reviews for select
using (is_public = true or public.current_role() = 'admin');
drop policy if exists "submit review" on public.reviews;
create policy "submit review" on public.reviews for insert
with check (user_id is null or user_id = auth.uid());
drop policy if exists "admin moderate reviews" on public.reviews;
create policy "admin moderate reviews" on public.reviews for update to authenticated
using (public.current_role() = 'admin') with check (public.current_role() = 'admin');
drop policy if exists "admin delete reviews" on public.reviews;
create policy "admin delete reviews" on public.reviews for delete to authenticated
using (public.current_role() = 'admin');

-- Orders: signed-in customers create and read only their own; admin reads/manages all; factory reads and updates status.
drop policy if exists "customer create order" on public.orders;
create policy "customer create order" on public.orders for insert to authenticated
with check (user_id is null or user_id = auth.uid());
drop policy if exists "customer own orders" on public.orders;
create policy "customer own orders" on public.orders for select to authenticated
using (user_id = auth.uid() or public.current_role() in ('admin','factory'));
drop policy if exists "admin update orders" on public.orders;
create policy "admin update orders" on public.orders for update to authenticated
using (public.current_role() = 'admin') with check (public.current_role() = 'admin');
drop policy if exists "factory update orders" on public.orders;
create policy "factory update orders" on public.orders for update to authenticated
using (public.current_role() in ('admin','factory')) with check (public.current_role() in ('admin','factory'));
drop policy if exists "admin delete orders" on public.orders;
create policy "admin delete orders" on public.orders for delete to authenticated
using (public.current_role() = 'admin');

-- IMPORTANT: after the first owner account signs up, manually promote it from SQL Editor:
-- update public.profiles set role='admin' where id=(select id from auth.users where email='YOUR_EMAIL');
-- Add a factory account the same way after that user signs up:
-- update public.profiles set role='factory' where id=(select id from auth.users where email='FACTORY_EMAIL');
