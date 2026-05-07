-- ─────────────────────────────────────────────────────────────
-- POLLS / ADMIN_REQUESTS / STORAGE — Supabase migration
-- Энэ файлыг Supabase SQL Editor дотор бүхэлд нь ажиллуулна уу.
-- (Code-той tохирсон column нэрс: polls.options=jsonb, admin_requests.from_uid+message)
-- ─────────────────────────────────────────────────────────────

create extension if not exists pgcrypto;

-- ─────────────────────────────────────────────────────────────
-- 1. POLLS
-- options нь jsonb массив: [{"id":"opt_0","label":"..."}, ...]
-- ─────────────────────────────────────────────────────────────
create table if not exists polls (
  id          uuid primary key default gen_random_uuid(),
  club_id     uuid not null references clubs(id) on delete cascade,
  question    text not null,
  options     jsonb not null,
  created_by  uuid references users(id) on delete set null,
  created_at  timestamptz not null default now()
);

create index if not exists polls_club_id_idx    on polls(club_id);
create index if not exists polls_created_at_idx on polls(created_at desc);

-- poll_votes — нэг хэрэглэгч нэг полл-д нэг л санал
create table if not exists poll_votes (
  id         uuid primary key default gen_random_uuid(),
  poll_id    uuid not null references polls(id) on delete cascade,
  option_id  text not null,
  user_id    uuid not null references users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (poll_id, user_id)
);

create index if not exists poll_votes_poll_id_idx on poll_votes(poll_id);

alter table polls       enable row level security;
alter table poll_votes  enable row level security;

-- polls policies
drop policy if exists "polls_select_all"        on polls;
drop policy if exists "polls_insert_admin"      on polls;
drop policy if exists "polls_update_admin"      on polls;
drop policy if exists "polls_delete_admin"      on polls;

create policy "polls_select_all" on polls for select using (true);

create policy "polls_insert_admin" on polls for insert with check (
  exists (select 1 from users
          where users.id = auth.uid()
            and (users.role = 'super_admin'
                 or (users.role = 'club_admin' and users.managed_club_id = polls.club_id)))
);

create policy "polls_update_admin" on polls for update using (
  exists (select 1 from users
          where users.id = auth.uid()
            and (users.role = 'super_admin'
                 or (users.role = 'club_admin' and users.managed_club_id = polls.club_id)))
);

create policy "polls_delete_admin" on polls for delete using (
  exists (select 1 from users
          where users.id = auth.uid()
            and (users.role = 'super_admin'
                 or (users.role = 'club_admin' and users.managed_club_id = polls.club_id)))
);

-- poll_votes policies
drop policy if exists "poll_votes_select_all"  on poll_votes;
drop policy if exists "poll_votes_insert_self" on poll_votes;
drop policy if exists "poll_votes_update_self" on poll_votes;
drop policy if exists "poll_votes_delete_self" on poll_votes;

create policy "poll_votes_select_all" on poll_votes for select using (true);
create policy "poll_votes_insert_self" on poll_votes for insert with check (auth.uid() = user_id);
create policy "poll_votes_update_self" on poll_votes for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "poll_votes_delete_self" on poll_votes for delete using (auth.uid() = user_id);


-- ─────────────────────────────────────────────────────────────
-- 2. ADMIN_REQUESTS — Клубийн тэргүүн → Super admin
-- (column нэрсүүд: from_uid, message  ← code-той тохируулсан)
-- ─────────────────────────────────────────────────────────────
create table if not exists admin_requests (
  id          uuid primary key default gen_random_uuid(),
  from_uid    uuid not null references users(id) on delete cascade,
  club_id     uuid references clubs(id) on delete set null,
  type        text not null check (type in ('general', 'complaint', 'suggestion')),
  message     text not null,
  status      text not null default 'pending' check (status in ('pending', 'in_review', 'resolved', 'rejected')),
  response    text,
  created_at  timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references users(id) on delete set null
);

create index if not exists admin_requests_status_idx     on admin_requests(status);
create index if not exists admin_requests_from_uid_idx   on admin_requests(from_uid);
create index if not exists admin_requests_created_at_idx on admin_requests(created_at desc);

alter table admin_requests enable row level security;

drop policy if exists "admin_requests_select_own_or_super" on admin_requests;
drop policy if exists "admin_requests_insert_admin"        on admin_requests;
drop policy if exists "admin_requests_update_super"        on admin_requests;
drop policy if exists "admin_requests_delete_super"        on admin_requests;

create policy "admin_requests_select_own_or_super" on admin_requests for select using (
  auth.uid() = from_uid
  or exists (select 1 from users where users.id = auth.uid() and users.role = 'super_admin')
);

create policy "admin_requests_insert_admin" on admin_requests for insert with check (
  auth.uid() = from_uid
  and exists (select 1 from users where users.id = auth.uid() and users.role = 'club_admin')
);

create policy "admin_requests_update_super" on admin_requests for update using (
  exists (select 1 from users where users.id = auth.uid() and users.role = 'super_admin')
);

create policy "admin_requests_delete_super" on admin_requests for delete using (
  exists (select 1 from users where users.id = auth.uid() and users.role = 'super_admin')
);


-- ─────────────────────────────────────────────────────────────
-- 3. STORAGE BUCKET — announcements (зураг upload-д шаардлагатай)
-- ─────────────────────────────────────────────────────────────
insert into storage.buckets (id, name, public)
  values ('announcements', 'announcements', true)
  on conflict (id) do nothing;

drop policy if exists "announcements_read_all"      on storage.objects;
drop policy if exists "announcements_insert_admins" on storage.objects;
drop policy if exists "announcements_update_admins" on storage.objects;
drop policy if exists "announcements_delete_admins" on storage.objects;

create policy "announcements_read_all" on storage.objects for select
  using (bucket_id = 'announcements');

create policy "announcements_insert_admins" on storage.objects for insert with check (
  bucket_id = 'announcements'
  and exists (select 1 from users
              where users.id = auth.uid()
                and users.role in ('club_admin', 'super_admin'))
);

create policy "announcements_update_admins" on storage.objects for update using (
  bucket_id = 'announcements'
  and exists (select 1 from users
              where users.id = auth.uid()
                and users.role in ('club_admin', 'super_admin'))
);

create policy "announcements_delete_admins" on storage.objects for delete using (
  bucket_id = 'announcements'
  and exists (select 1 from users
              where users.id = auth.uid()
                and users.role in ('club_admin', 'super_admin'))
);


-- ─────────────────────────────────────────────────────────────
-- 4. avatars bucket (хэрэв байхгүй бол нэмж үүсгэх)
-- ─────────────────────────────────────────────────────────────
insert into storage.buckets (id, name, public)
  values ('avatars', 'avatars', true)
  on conflict (id) do nothing;

drop policy if exists "avatars_read_all"      on storage.objects;
drop policy if exists "avatars_write_self"    on storage.objects;
drop policy if exists "avatars_update_self"   on storage.objects;
drop policy if exists "avatars_delete_self"   on storage.objects;

create policy "avatars_read_all" on storage.objects for select using (bucket_id = 'avatars');

create policy "avatars_write_self" on storage.objects for insert with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "avatars_update_self" on storage.objects for update using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "avatars_delete_self" on storage.objects for delete using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);
