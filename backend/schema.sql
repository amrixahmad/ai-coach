-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- PROFILES TABLE (Public profile info)
create table public.profiles (
  id uuid references auth.users not null primary key,
  full_name text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ANALYSES TABLE (Store video results)
create table public.analyses (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) not null,
  video_url text, -- Path in Supabase Storage
  gemini_analysis jsonb, -- Full JSON output from Gemini
  tracking_data jsonb, -- Pose tracking data
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- STORAGE BUCKET
insert into storage.buckets (id, name, public) values ('videos', 'videos', false);

-- ROW LEVEL SECURITY (RLS) POLICIES
alter table public.profiles enable row level security;
alter table public.analyses enable row level security;

-- Profiles policies
create policy "Public profiles are viewable by everyone."
  on profiles for select
  using ( true );

create policy "Users can insert their own profile."
  on profiles for insert
  with check ( auth.uid() = id );

create policy "Users can update own profile."
  on profiles for update
  using ( auth.uid() = id );

-- Analyses policies
create policy "Users can view their own analyses."
  on analyses for select
  using ( auth.uid() = user_id );

create policy "Users can insert their own analyses."
  on analyses for insert
  with check ( auth.uid() = user_id );

-- Storage policies
create policy "Give users access to own folder 1u753_0" on storage.objects
  for select
  to public
  using (bucket_id = 'videos' AND auth.uid()::text = (storage.foldername(name))[1]);

create policy "Give users access to own folder 1u753_1" on storage.objects
  for insert
  to public
  with check (bucket_id = 'videos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- TRIGGER: Create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data ->> 'full_name');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
