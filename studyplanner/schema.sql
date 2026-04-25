-- 學生課業複習規劃 - Supabase Schema
-- 在 Supabase Dashboard → SQL Editor 貼上並執行
-- 已建表者重跑也安全 (用 if not exists / add column if not exists)

create extension if not exists pgcrypto;

create table if not exists students (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  grade text,
  daily_goal_minutes int default 60,
  created_at timestamptz default now()
);
alter table students add column if not exists daily_goal_minutes int default 60;

create table if not exists subjects (
  id uuid primary key default gen_random_uuid(),
  student_id uuid references students(id) on delete cascade,
  name text not null,
  color text default '#6366f1',
  created_at timestamptz default now()
);

create table if not exists chapters (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid references subjects(id) on delete cascade,
  name text not null,
  status text default 'not_started',  -- not_started / reviewing / done / redo
  order_index int default 0,
  resources jsonb default '[]'::jsonb,  -- [{title, url}]
  created_at timestamptz default now()
);
alter table chapters add column if not exists resources jsonb default '[]'::jsonb;

create table if not exists exams (
  id uuid primary key default gen_random_uuid(),
  student_id uuid references students(id) on delete cascade,
  name text not null,
  exam_date date not null,
  description text,
  created_at timestamptz default now()
);

create table if not exists exam_chapters (
  exam_id uuid references exams(id) on delete cascade,
  chapter_id uuid references chapters(id) on delete cascade,
  primary key (exam_id, chapter_id)
);

create table if not exists tasks (
  id uuid primary key default gen_random_uuid(),
  student_id uuid references students(id) on delete cascade,
  subject_id uuid references subjects(id) on delete set null,
  chapter_id uuid references chapters(id) on delete set null,
  title text not null,
  task_date date not null,
  done boolean default false,
  created_at timestamptz default now()
);

create table if not exists study_logs (
  id uuid primary key default gen_random_uuid(),
  student_id uuid references students(id) on delete cascade,
  subject_id uuid references subjects(id) on delete set null,
  log_date date not null,
  minutes int not null check (minutes >= 0),
  note text,
  created_at timestamptz default now()
);

create table if not exists recurring_templates (
  id uuid primary key default gen_random_uuid(),
  student_id uuid references students(id) on delete cascade,
  subject_id uuid references subjects(id) on delete set null,
  chapter_id uuid references chapters(id) on delete set null,
  title text not null,
  weekday int not null check (weekday between 0 and 6),  -- 0=週日, 6=週六
  active boolean default true,
  created_at timestamptz default now()
);

-- 家用單機免登入,關閉 RLS
alter table public.students            disable row level security;
alter table public.subjects            disable row level security;
alter table public.chapters            disable row level security;
alter table public.exams               disable row level security;
alter table public.exam_chapters       disable row level security;
alter table public.tasks               disable row level security;
alter table public.study_logs          disable row level security;
alter table public.recurring_templates disable row level security;

-- 備案:若關閉 RLS 失敗,改成保留 RLS + 開放 anon/authenticated 全權限
-- do $$
-- declare t text;
-- begin
--   for t in select unnest(array['students','subjects','chapters','exams','exam_chapters','tasks','study_logs','recurring_templates']) loop
--     execute format('alter table public.%I enable row level security', t);
--     execute format('drop policy if exists "open all anon" on public.%I', t);
--     execute format('drop policy if exists "open all auth" on public.%I', t);
--     execute format('create policy "open all anon" on public.%I for all to anon using (true) with check (true)', t);
--     execute format('create policy "open all auth" on public.%I for all to authenticated using (true) with check (true)', t);
--   end loop;
-- end $$;

notify pgrst, 'reload schema';
