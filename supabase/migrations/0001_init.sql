-- NoteBook UM Initial Database Migration (PRD v0.3 Section 4.2 & 4.3)

-- 1. Custom Types / Enums
create type task_status as enum ('todo', 'in_progress', 'done');
create type task_priority as enum ('low', 'medium', 'high');
create type due_mode as enum ('none', 'fixed', 'next_session');

-- 2. Profiles Table
create table profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text check (char_length(display_name) <= 60),
  timezone text not null default 'Asia/Makassar',
  created_at timestamptz not null default now()
);

-- 3. Courses Table
create table courses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references profiles (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 100),
  code text check (char_length(code) <= 20),
  lecturer text check (char_length(lecturer) <= 100),
  color text not null default '#3B82F6' check (color ~ '^#[0-9A-Fa-f]{6}$'),
  created_at timestamptz not null default now()
);

-- 4. Class Sessions Table (Weekly recurring slots)
create table class_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references profiles (id) on delete cascade,
  course_id uuid not null references courses (id) on delete cascade,
  weekday smallint not null check (weekday between 1 and 7), -- ISO: 1=Senin ... 7=Minggu
  start_time time not null,
  end_time time not null,
  room text check (char_length(room) <= 50),
  valid_from date,
  valid_until date,
  created_at timestamptz not null default now(),
  check (end_time > start_time),
  check (valid_until is null or valid_from is null or valid_until >= valid_from)
);

-- 5. Tasks Table
create table tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references profiles (id) on delete cascade,
  course_id uuid references courses (id) on delete set null,
  title text not null check (char_length(title) between 1 and 150),
  notes text check (char_length(notes) <= 2000),
  status task_status not null default 'todo',
  priority task_priority not null default 'medium',
  due_mode due_mode not null default 'none',
  due_at timestamptz,
  remind_before_minutes int[] not null default '{1440,60}',
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (due_mode <> 'fixed' or due_at is not null),
  check (due_mode <> 'none' or due_at is null),
  check (cardinality(remind_before_minutes) <= 5)
);

-- 6. Indexes for Performance
create index tasks_user_due_idx on tasks (user_id, status, due_at);
create index tasks_course_idx on tasks (course_id);
create index sessions_user_day_idx on class_sessions (user_id, weekday, start_time);
create index sessions_course_idx on class_sessions (course_id);

-- 7. Security & Row Level Security (RLS)
revoke all on all tables in schema public from anon;

alter table profiles enable row level security;
alter table courses enable row level security;
alter table class_sessions enable row level security;
alter table tasks enable row level security;

create policy profiles_select_own on profiles for select to authenticated
  using (id = (select auth.uid()));

create policy profiles_update_own on profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

create policy courses_own on courses for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy sessions_own on class_sessions for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid())
  and exists (select 1 from courses c where c.id = course_id and c.user_id = (select auth.uid())));

create policy tasks_own on tasks for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid())
  and (course_id is null or exists (select 1 from courses c where c.id = course_id and c.user_id = (select auth.uid()))));

-- Column-level security on profiles
revoke update on profiles from authenticated;
grant update (display_name, timezone) on profiles to authenticated;

-- 8. Triggers & Helpers
-- Automatically create profile on new user registration
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name, timezone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
    'Asia/Makassar'
  );
  return new;
end;
$$;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Trigger for auto updated_at on tasks
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger on_task_updated
  before update on tasks
  for each row execute procedure public.set_updated_at();
