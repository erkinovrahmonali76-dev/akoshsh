-- AKOSH v3 database upgrade
create extension if not exists "pgcrypto";

create table if not exists public.profiles (id uuid primary key references auth.users(id) on delete cascade, username text unique not null, display_name text, bio text default '', avatar_url text default '', is_private boolean default false, created_at timestamptz default now());
create table if not exists public.posts (id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade, media_url text not null, media_type text not null check (media_type in ('image','video')), caption text default '', location text default '', created_at timestamptz default now());
create table if not exists public.follows (follower_id uuid references public.profiles(id) on delete cascade, following_id uuid references public.profiles(id) on delete cascade, created_at timestamptz default now(), primary key(follower_id,following_id), check(follower_id<>following_id));
create table if not exists public.likes (user_id uuid references public.profiles(id) on delete cascade, post_id uuid references public.posts(id) on delete cascade, created_at timestamptz default now(), primary key(user_id,post_id));
create table if not exists public.comments (id uuid primary key default gen_random_uuid(), post_id uuid references public.posts(id) on delete cascade, user_id uuid references public.profiles(id) on delete cascade, body text not null, created_at timestamptz default now());

alter table public.profiles enable row level security; alter table public.posts enable row level security; alter table public.follows enable row level security; alter table public.likes enable row level security; alter table public.comments enable row level security;

drop policy if exists "profiles public read" on public.profiles; create policy "profiles public read" on public.profiles for select using (true);
drop policy if exists "own profile insert" on public.profiles; create policy "own profile insert" on public.profiles for insert with check (auth.uid()=id);
drop policy if exists "own profile update" on public.profiles; create policy "own profile update" on public.profiles for update using (auth.uid()=id);
drop policy if exists "posts public read" on public.posts; create policy "posts public read" on public.posts for select using (true);
drop policy if exists "own posts insert" on public.posts; create policy "own posts insert" on public.posts for insert with check (auth.uid()=user_id);
drop policy if exists "own posts update" on public.posts; create policy "own posts update" on public.posts for update using (auth.uid()=user_id);
drop policy if exists "own posts delete" on public.posts; create policy "own posts delete" on public.posts for delete using (auth.uid()=user_id);
drop policy if exists "follows read" on public.follows; create policy "follows read" on public.follows for select using (true);
drop policy if exists "follow own insert" on public.follows; create policy "follow own insert" on public.follows for insert with check (auth.uid()=follower_id);
drop policy if exists "follow own delete" on public.follows; create policy "follow own delete" on public.follows for delete using (auth.uid()=follower_id);
drop policy if exists "likes read" on public.likes; create policy "likes read" on public.likes for select using (true);
drop policy if exists "likes own insert" on public.likes; create policy "likes own insert" on public.likes for insert with check (auth.uid()=user_id);
drop policy if exists "likes own delete" on public.likes; create policy "likes own delete" on public.likes for delete using (auth.uid()=user_id);
drop policy if exists "comments read" on public.comments; create policy "comments read" on public.comments for select using (true);
drop policy if exists "comments own insert" on public.comments; create policy "comments own insert" on public.comments for insert with check (auth.uid()=user_id);
drop policy if exists "comments own delete" on public.comments; create policy "comments own delete" on public.comments for delete using (auth.uid()=user_id);

-- New accounts automatically get a profile from signup metadata.
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
declare base_username text; final_username text; n int:=0;
begin
 base_username:=lower(coalesce(new.raw_user_meta_data->>'username','user_'||substr(new.id::text,1,8)));
 base_username:=regexp_replace(base_username,'[^a-z0-9._]','','g');
 if length(base_username)<3 then base_username:='user_'||substr(new.id::text,1,8); end if;
 final_username:=left(base_username,30);
 while exists(select 1 from public.profiles where username=final_username) loop n:=n+1; final_username:=left(base_username,25)||'_'||n; end loop;
 insert into public.profiles(id,username,display_name) values(new.id,final_username,coalesce(new.raw_user_meta_data->>'display_name',final_username)) on conflict(id) do nothing;
 return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

-- Backfill any profiles missing for existing auth users. Username is generated safely from email prefix.
insert into public.profiles(id,username,display_name)
select u.id,
       left(regexp_replace(lower(split_part(coalesce(u.email,'user_'||substr(u.id::text,1,8)),'@',1)),'[^a-z0-9._]','','g'),24)||'_'||substr(u.id::text,1,4),
       coalesce(u.raw_user_meta_data->>'display_name',split_part(coalesce(u.email,'AKOSH User'),'@',1))
from auth.users u left join public.profiles p on p.id=u.id where p.id is null
on conflict(id) do nothing;
