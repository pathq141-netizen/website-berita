-- ALFATH × DONWAY NEWSROOM — Supabase schema
-- Run in Supabase SQL Editor. Review before applying to an existing project.
create extension if not exists pgcrypto;

create type public.app_role as enum ('reader', 'admin');
create type public.article_status as enum ('draft', 'published');

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  role public.app_role not null default 'reader',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.articles (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 180),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  summary text not null default '' check (char_length(summary) <= 320),
  content text not null default '',
  category text not null check (category in ('AI','Technology','Software','Gadget','Digital Business','Cybersecurity','Innovation')),
  author text not null default 'Redaksi DONWAY',
  thumbnail_url text,
  cover_url text,
  status public.article_status not null default 'draft',
  published_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint published_has_date check (status <> 'published' or published_at is not null)
);
create index if not exists articles_publication_idx on public.articles(status, published_at desc);
create index if not exists articles_category_idx on public.articles(category, status, published_at desc);
create index if not exists articles_created_idx on public.articles(created_at desc);
create index if not exists articles_slug_idx on public.articles(slug);

create table if not exists public.media (
  id uuid primary key default gen_random_uuid(),
  storage_path text not null unique,
  public_url text,
  filename text not null,
  mime_type text not null check (mime_type in ('image/jpeg','image/png','image/webp','image/avif','video/mp4','video/webm')),
  size_bytes bigint not null check (size_bytes > 0 and size_bytes <= 52428800),
  uploaded_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create index if not exists media_created_idx on public.media(created_at desc);

create or replace function public.touch_updated_at()
returns trigger language plpgsql set search_path = public as $$
begin new.updated_at = now(); return new; end; $$;
drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at before update on public.profiles for each row execute function public.touch_updated_at();
drop trigger if exists articles_touch_updated_at on public.articles;
create trigger articles_touch_updated_at before update on public.articles for each row execute function public.touch_updated_at();

-- Create a profile for every new auth user; role is always reader.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id, display_name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name','Reader'), 'reader')
  on conflict (id) do nothing;
  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin');
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

alter table public.profiles enable row level security;
alter table public.articles enable row level security;
alter table public.media enable row level security;

drop policy if exists "read own profile" on public.profiles;
create policy "read own profile" on public.profiles for select to authenticated using (id = auth.uid() or public.is_admin());
drop policy if exists "update own display name" on public.profiles;
create policy "update own display name" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid() and role = (select p.role from public.profiles p where p.id = auth.uid()));
-- No insert/update policy lets users self-assign admin. The trigger is the normal profile creation path.
drop policy if exists "public reads published articles" on public.articles;
create policy "public reads published articles" on public.articles for select to anon, authenticated using (status = 'published' or public.is_admin());
drop policy if exists "admins insert articles" on public.articles;
create policy "admins insert articles" on public.articles for insert to authenticated with check (public.is_admin() and created_by = auth.uid());
drop policy if exists "admins update articles" on public.articles;
create policy "admins update articles" on public.articles for update to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "admins delete articles" on public.articles;
create policy "admins delete articles" on public.articles for delete to authenticated using (public.is_admin());

drop policy if exists "admins read media metadata" on public.media;
create policy "admins read media metadata" on public.media for select to authenticated using (public.is_admin());
drop policy if exists "admins insert media metadata" on public.media;
create policy "admins insert media metadata" on public.media for insert to authenticated with check (public.is_admin() and uploaded_by = auth.uid());
drop policy if exists "admins delete media metadata" on public.media;
create policy "admins delete media metadata" on public.media for delete to authenticated using (public.is_admin());

-- Storage bucket setup: run once. File-size cap 50 MB and MIME allowlist.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('news-media', 'news-media', true, 52428800, array['image/jpeg','image/png','image/webp','image/avif','video/mp4','video/webm'])
on conflict (id) do update set public = true, file_size_limit = 52428800,
allowed_mime_types = array['image/jpeg','image/png','image/webp','image/avif','video/mp4','video/webm'];

drop policy if exists "public read news media" on storage.objects;
create policy "public read news media" on storage.objects for select to anon, authenticated using (bucket_id = 'news-media');
drop policy if exists "admins upload news media" on storage.objects;
create policy "admins upload news media" on storage.objects for insert to authenticated with check (bucket_id = 'news-media' and public.is_admin());
drop policy if exists "admins update news media" on storage.objects;
create policy "admins update news media" on storage.objects for update to authenticated using (bucket_id = 'news-media' and public.is_admin()) with check (bucket_id = 'news-media' and public.is_admin());
drop policy if exists "admins delete news media" on storage.objects;
create policy "admins delete news media" on storage.objects for delete to authenticated using (bucket_id = 'news-media' and public.is_admin());

-- IMPORTANT: promote first admin only from trusted Supabase SQL Editor, after verifying user UUID:
-- update public.profiles set role = 'admin' where id = 'VERIFIED-AUTH-USER-UUID';
-- Never expose this operation to public frontend. Keep Supabase service role key private.
