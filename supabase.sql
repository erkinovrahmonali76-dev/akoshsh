-- AKOSH Supabase starter schema
create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  display_name text,
  bio text default '',
  avatar_url text default '',
  is_private boolean default false,
  created_at timestamptz default now()
);

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  media_url text not null,
  media_type text not null check (media_type in ('image','video')),
  caption text default '',
  location text default '',
  created_at timestamptz default now()
);

create table if not exists public.reels (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  video_url text not null,
  caption text default '',
  created_at timestamptz default now()
);

create table if not exists public.stories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  media_url text not null,
  media_type text not null check (media_type in ('image','video')),
  caption text default '',
  created_at timestamptz default now()
);

create table if not exists public.follows (
  follower_id uuid references public.profiles(id) on delete cascade,
  following_id uuid references public.profiles(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);

create table if not exists public.likes (
  user_id uuid references public.profiles(id) on delete cascade,
  post_id uuid references public.posts(id) on delete cascade,
  created_at timestamptz default now(),
  primary key(user_id,post_id)
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid references public.posts(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  body text not null,
  created_at timestamptz default now()
);

create table if not exists public.saved_posts (
  user_id uuid references public.profiles(id) on delete cascade,
  post_id uuid references public.posts(id) on delete cascade,
  created_at timestamptz default now(),
  primary key(user_id,post_id)
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now()
);

create table if not exists public.conversation_members (
  conversation_id uuid references public.conversations(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  primary key(conversation_id,user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid references public.conversations(id) on delete cascade,
  sender_id uuid references public.profiles(id) on delete cascade,
  body text default '',
  media_url text default '',
  created_at timestamptz default now(),
  read_at timestamptz
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid references public.profiles(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete cascade,
  type text not null,
  entity_id uuid,
  read boolean default false,
  created_at timestamptz default now()
);

create table if not exists public.blocks (
  blocker_id uuid references public.profiles(id) on delete cascade,
  blocked_id uuid references public.profiles(id) on delete cascade,
  created_at timestamptz default now(),
  primary key(blocker_id,blocked_id),
  check(blocker_id <> blocked_id)
);

alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.reels enable row level security;
alter table public.stories enable row level security;
alter table public.follows enable row level security;
alter table public.likes enable row level security;
alter table public.comments enable row level security;
alter table public.saved_posts enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;
alter table public.blocks enable row level security;

create policy "profiles public read" on public.profiles for select using (true);
create policy "own profile insert" on public.profiles for insert with check (auth.uid() = id);
create policy "own profile update" on public.profiles for update using (auth.uid() = id);

create policy "posts public read" on public.posts for select using (true);
create policy "own posts insert" on public.posts for insert with check (auth.uid() = user_id);
create policy "own posts update" on public.posts for update using (auth.uid() = user_id);
create policy "own posts delete" on public.posts for delete using (auth.uid() = user_id);

create policy "reels public read" on public.reels for select using (true);
create policy "own reels insert" on public.reels for insert with check (auth.uid() = user_id);
create policy "own reels delete" on public.reels for delete using (auth.uid() = user_id);

create policy "stories public read" on public.stories for select using (created_at > now() - interval '24 hours');
create policy "own stories insert" on public.stories for insert with check (auth.uid() = user_id);
create policy "own stories delete" on public.stories for delete using (auth.uid() = user_id);

create policy "follows read" on public.follows for select using (true);
create policy "follow own insert" on public.follows for insert with check (auth.uid() = follower_id);
create policy "follow own delete" on public.follows for delete using (auth.uid() = follower_id);

create policy "likes read" on public.likes for select using (true);
create policy "likes own insert" on public.likes for insert with check (auth.uid() = user_id);
create policy "likes own delete" on public.likes for delete using (auth.uid() = user_id);

create policy "comments read" on public.comments for select using (true);
create policy "comments own insert" on public.comments for insert with check (auth.uid() = user_id);
create policy "comments own delete" on public.comments for delete using (auth.uid() = user_id);

create policy "saved own read" on public.saved_posts for select using (auth.uid() = user_id);
create policy "saved own insert" on public.saved_posts for insert with check (auth.uid() = user_id);
create policy "saved own delete" on public.saved_posts for delete using (auth.uid() = user_id);

create policy "blocks own read" on public.blocks for select using (auth.uid() = blocker_id);
create policy "blocks own insert" on public.blocks for insert with check (auth.uid() = blocker_id);
create policy "blocks own delete" on public.blocks for delete using (auth.uid() = blocker_id);

-- Storage buckets to create in Dashboard:
-- avatars, posts, reels, stories, messages
