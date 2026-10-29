-- NoteBook UM Seed Data (PRD v0.3 Section 4.4 - Rani Putri, WITA)

do $$
declare
  demo_user_id uuid := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
  c_algo uuid := 'b1111111-1111-1111-1111-111111111111';
  c_kalkulus uuid := 'b2222222-2222-2222-2222-222222222222';
  c_basdat uuid := 'b3333333-3333-3333-3333-333333333333';
  c_inggris uuid := 'b4444444-4444-4444-4444-444444444444';
begin
  -- 1. Insert Profile
  insert into profiles (id, display_name, timezone)
  values (demo_user_id, 'Rani Putri', 'Asia/Makassar')
  on conflict (id) do update set display_name = 'Rani Putri', timezone = 'Asia/Makassar';

  -- 2. Insert Courses
  insert into courses (id, user_id, name, code, lecturer, color)
  values
    (c_algo, demo_user_id, 'Algoritma & Pemrograman', 'IF1101', 'Dr. Budi Santoso', '#3B82F6'),
    (c_kalkulus, demo_user_id, 'Kalkulus II', 'MA1201', 'Ir. Siti Aminah, M.Si.', '#10B981'),
    (c_basdat, demo_user_id, 'Basis Data', 'IF1203', 'Andi Wijaya, M.Kom.', '#F59E0B'),
    (c_inggris, demo_user_id, 'Bahasa Inggris Teknik', 'UM1101', 'Dewi Lestari, M.Pd.', '#8B5CF6')
  on conflict (id) do nothing;

  -- 3. Insert Class Sessions
  insert into class_sessions (user_id, course_id, weekday, start_time, end_time, room)
  values
    (demo_user_id, c_algo, 1, '08:00', '10:30', 'Lab Komputer 2'),
    (demo_user_id, c_algo, 4, '13:00', '14:40', 'R.301'),
    (demo_user_id, c_kalkulus, 2, '10:00', '11:40', 'R.204'),
    (demo_user_id, c_kalkulus, 5, '08:00', '09:40', 'R.204'),
    (demo_user_id, c_basdat, 3, '13:00', '15:30', 'Lab Basis Data'),
    (demo_user_id, c_inggris, 4, '09:00', '10:40', 'R.101')
  on conflict do nothing;

  -- 4. Insert Tasks
  insert into tasks (user_id, course_id, title, notes, status, priority, due_mode, due_at, completed_at)
  values
    (demo_user_id, c_algo, 'Laporan praktikum sorting', 'Format PDF, nama file NIM_Nama', 'todo', 'high', 'next_session', now() + interval '2 days', null),
    (demo_user_id, c_kalkulus, 'Latihan soal integral Bab 5', 'Nomor 1–10', 'in_progress', 'medium', 'fixed', (date_trunc('day', now()) + interval '1 day 23 hours 59 minutes'), null),
    (demo_user_id, c_basdat, 'ERD sistem perpustakaan', 'Minimal 5 entitas', 'todo', 'high', 'fixed', (date_trunc('day', now()) + interval '5 days 17 hours'), null),
    (demo_user_id, c_inggris, 'Latihan presentasi technical writing', 'Durasi 5 menit', 'todo', 'medium', 'next_session', now() + interval '3 days', null),
    (demo_user_id, c_basdat, 'Baca materi normalisasi', '–', 'todo', 'low', 'none', null, null),
    (demo_user_id, null, 'Daftar PKM', 'Siapkan proposal singkat', 'todo', 'medium', 'fixed', (date_trunc('day', now()) + interval '7 days 12 hours'), null),
    (demo_user_id, c_kalkulus, 'Rangkuman limit dan kontinuitas', 'Sudah dikumpulkan', 'done', 'low', 'none', null, now() - interval '2 days')
  on conflict do nothing;
end;
$$;
