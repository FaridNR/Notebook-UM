# Architectural & Technical Decisions — NoteBook UM (MVP)

Dokumen ini mencatat keputusan arsitektural, teknis, dan kompromi desain yang diambil selama pengembangan aplikasi NoteBook UM sesuai arahan PRD v0.3.

---

## 1. Pemilihan Pola State Management & Reaktivitas
- **Keputusan**: Menggunakan `ChangeNotifier` berbasis ViewModel (`AppState`) yang terpusat dan reaktif untuk mengelola seluruh data kuliah, sesi jadwal, tugas, filter, tema, dan preferensi pengguna.
- **Rasional**: Memastikan performa tinggi tanpa overhead boilerplate berlebih untuk MVP fase awal, dengan kemampuan sinkronisasi instan ke seluruh tab (Hari Ini, Jadwal, Tugas, Matkul, Akun) dan timer per menit tanpa reload.
- **Dukungan Fase Berikutnya**: Struktur data dan model telah disiapkan (`toJson`, `fromJson`, immutable field copy) agar mudah dimigrasikan ke Riverpod atau Supabase Realtime Stream saat integrasi backend aktif.

## 2. Aturan Logika Waktu & Zona Waktu (WITA UTC+8)
- **Keputusan**: Implementasi utilitas waktu mandiri di `lib/core/time/time_service.dart`:
  - Default timezone: `Asia/Makassar` (WITA, UTC+8).
  - Penghitungan status kuliah:
    - `akan_datang`: waktu sekarang < waktu mulai slot.
    - `berlangsung`: waktu mulai slot <= waktu sekarang < waktu selesai slot.
    - `selesai`: waktu sekarang >= waktu selesai slot.
  - Tenggat `next_session`:
    - Titik acuan: `created_at` tugas.
    - `due_at`: waktu mulai dari slot pertemuan berikutnya setelah titik acuan (dalam batas `valid_from` dan `valid_until`).
    - Nilai ini disimpan persisten agar tidak bergeser sendiri setiap hari.
    - Penghitungan ulang otomatis dijalankan saat jadwal mata kuliah diubah/dihapus untuk tugas yang belum selesai dan belum lewat tenggat.
- **Rasional**: Mematuhi aturan ketat Bagian 1.7 PRD dan menghindari drift waktu.

## 3. Desain UI Anti-Slop (NoteBook UM Design System)
- **Keputusan**: 
  - Tidak menggunakan trailing period pada judul layar atau header modal (`Hari Ini`, `Mata Kuliah`, `Tambah Tugas`).
  - Mengganti border 1px kaku dengan *surface tone-steps* (`#F1F3F5` & `#F8F9FA` pada Light Mode, `#090A0C` & `#18191E` pada Dark Mode).
  - Grounded dock navigation 5 tab yang menempel pada batas bawah layar (bukan floating dock).
  - Teks minimal 12px dengan sentence-case alami, menghindari micro-font 9-10px atau robotic all-caps.
- **Rasional**: Menjaga estetika aplikasi akademik modern, tenang, dan padat informasi sesuai panduan desain NoteBook UM.

## 4. Keamanan & Guardrails Supabase (RLS & Anon Access)
- **Keputusan**:
  - Semua tabel (`profiles`, `courses`, `class_sessions`, `tasks`) memiliki Row Level Security (RLS) aktif dengan aturan kepemilikan `user_id = auth.uid()`.
  - Akses `anon` dicabut secara eksplisit (`REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon`).
  - `SUPABASE_SERVICE_ROLE_KEY` dilarang keras masuk ke dalam repositori atau kode klien.
  - Skema database diisolasi dalam `supabase/migrations/0001_init.sql` dan data demo dalam `supabase/seed.sql`.

## 5. Konfirmasi Tindakan Destruktif
- **Keputusan**: Hapus akun dan reset data lokal memerlukan konfirmasi eksplisit dengan mengetikkan teks **"HAPUS"** pada modal konfirmasi sesuai PRD Bagian 1.5 Flow F.
- **Rasional**: Mencegah kehilangan data tidak sengaja oleh pengguna mahasiswa.
