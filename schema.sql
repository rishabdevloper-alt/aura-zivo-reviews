-- Run this entire file in Supabase Dashboard > SQL Editor > New query.
create table if not exists public.reviews (
  id bigint generated always as identity primary key,
  rating numeric(2,1) not null check (rating >= 0.5 and rating <= 5 and rating * 2 = floor(rating * 2)),
  note text not null default '' check (char_length(note) <= 1000),
  created_at timestamptz not null default now()
);
create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.reviews enable row level security;
alter table public.admin_users enable row level security;
-- Anyone can submit a rating and optional note. No public read, edit or delete.
drop policy if exists "Anyone can submit reviews" on public.reviews;
create policy "Anyone can submit reviews" on public.reviews
for insert to anon, authenticated
with check (rating >= 0.5 and rating <= 5 and rating * 2 = floor(rating * 2) and char_length(note) <= 1000);
-- An admin can see their own admin-list entry.
drop policy if exists "Admins can view own admin entry" on public.admin_users;
create policy "Admins can view own admin entry" on public.admin_users
for select to authenticated using (user_id = auth.uid());
-- Only approved admin accounts can read reviews.
drop policy if exists "Admins can read reviews" on public.reviews;
create policy "Admins can read reviews" on public.reviews
for select to authenticated using (
  exists (select 1 from public.admin_users au where au.user_id = auth.uid())
);
