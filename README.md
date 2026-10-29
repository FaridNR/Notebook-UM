# NoteBook UM — Aplikasi Catatan Tugas & Jadwal Kuliah (MVP)

Aplikasi mobile Flutter untuk mahasiswa yang menghubungkan catatan tugas dengan jadwal kuliah secara *real-time*. Desain mengadopsi prinsip **NoteBook UM Anti-Slop Design System** (pemisahan ruang via *surface tone-steps*, tipografi alami tanpa *trailing periods*, dock navigasi menempel di bawah, dan palet warna akademik beridentitas kuat).

---

## 🚀 Fitur Utama & Kepatuhan PRD v0.3

1. **Layar Hari Ini (Live Beranda)**:
   - Status kuliah aktif *real-time* (`akan_datang`, `berlangsung`, `selesai`) dengan *progress bar* durasi dan hitung mundur sisa waktu yang diperbarui otomatis setiap menit.
   - Deteksi otomatis sesi kelas hari ini dan tugas terkait sesi kuliah aktif.
   - Daftar tugas mendesak (< 24 jam) dengan interaksi centang selesai dan *tactile undo toast* 5 detik.
   - Tampilan *empty-state*: *"Belum ada kelas hari ini. Santai dulu, atau cicil tugasmu."* bila tidak ada jadwal kuliah.

2. **Jadwal Kuliah (Grid & Strip Mingguan)**:
   - Kalender *7-day strip* (Senin–Minggu) dengan indikator titik warna matkul.
   - Beralih tampilan antara agenda harian dan rekap slot pekan ini.
   - Tambah slot jadwal baru dan kelola slot dengan dialog interaktif.

3. **Daftar Tugas & Filter Fleksibel**:
   - Pencarian instan berdasarkan judul tugas, catatan, atau nama mata kuliah.
   - Filter tab status: *Semua*, *Mendesak*, *Next Session*, *Mendatang*, *Selesai*.
   - *Filter rail* mata kuliah dinamis.
   - Modal detail tugas untuk menandai selesai, membuka kembali, atau menghapus tugas.

4. **Pencatatan Tugas Cepat (`AddTaskSheet`)**:
   - Deteksi otomatis kelas yang sedang aktif atau terdekat.
   - 3 mode tenggat sesuai PRD:
     - **Next Session**: Tenggat dihitung otomatis ke jam mulai pertemuan kuliah berikutnya setelah `created_at` (berdasarkan `valid_from` & `valid_until`).
     - **Pilih Tanggal**: Pemilihan kalender tanggal dan jam spesifik.
     - **Tanpa Tenggat**: Tugas fleksibel tanpa batas waktu kaku.
   - Pemilihan prioritas (*Rendah*, *Sedang*, *Tinggi*) dan switch pengingat notifikasi lokal.

5. **Mata Kuliah & Beban Studi**:
   - Ringkasan beban studi semester (total SKS terhadap batas 24 SKS).
   - Tambah mata kuliah lengkap dengan nama, kode, dosen, SKS, dan warna identitas akademik.
   - Modal kelola matkul dan hapus matkul (dengan aturan cascade pengalihan tugas `next_session` ke mode `fixed` mandiri).

6. **Pengaturan, Privasi & Keamanan Akun**:
   - Edit nama profil mahasiswa dan pemilihan zona waktu (*Asia/Makassar WITA*, *Asia/Jakarta WIB*, *Asia/Jayapura WIT*).
   - Pengaturan sakelar notifikasi H-24 dan H-1 jam.
   - Toggle tema *Light Mode* dan *Dark Mode (OLED Black)*.
   - Ekspor seluruh basis data ke format JSON.
   - Tombol keluar dari sesi (*logout*).
   - Zona berbahaya penghapusan data dengan kewajiban mengetikkan kata **"HAPUS"** sebelum tombol aktif.

7. **Autentikasi Pribadi**:
   - Layar masuk akun pemilik tunggal dengan validasi ketat kata sandi minimal 10 karakter.

---

## 🛠️ Struktur Proyek

```
/
├── lib/
│   ├── core/
│   │   └── time/
│   │       └── time_service.dart     # Logika getClassStatus, calculateNextSession, zona WITA
│   ├── models/
│   │   ├── course.dart              # Model Mata Kuliah & identitas warna
│   │   ├── schedule_slot.dart       # Model Slot Jadwal mingguan
│   │   └── task.dart                # Model Tugas & 3 mode tenggat
│   ├── state/
│   │   └── app_state.dart           # Reaktif AppState (ChangeNotifier) + timer per menit
│   ├── theme/
│   │   └── app_theme.dart           # Tone step colors & tema Material 3
│   ├── widgets/
│   │   ├── add_task_sheet.dart      # Modal sheet tambah tugas cepat
│   │   ├── course_badge.dart        # Badge kode matkul solid/outline
│   │   ├── dock_navigation.dart     # Grounded bottom dock 5 tab
│   │   └── undo_toast.dart          # Bar undo 5 detik
│   ├── screens/
│   │   ├── auth_screen.dart         # Layar login & validasi password >= 10 karakter
│   │   ├── today_screen.dart        # Layar Hari Ini & live kelas
│   │   ├── schedule_screen.dart     # Layar Jadwal mingguan
│   │   ├── tasks_screen.dart        # Layar Daftar tugas & filter
│   │   ├── courses_screen.dart      # Layar Manajemen mata kuliah & SKS
│   │   └── settings_screen.dart     # Layar Pengaturan, privasi & ekspor JSON
│   └── main.dart                    # Inisialisasi app & observer siklus hidup (resumed)
├── supabase/
│   ├── migrations/
│   │   └── 0001_init.sql            # Skema lengkap, RLS, enums, triggers
│   └── seed.sql                     # Data demo awal "Rani Putri" (WITA)
├── test/
│   ├── time_logic_test.dart         # Unit test logika waktu, batas menit & next_session
│   └── widget_test.dart             # Smoke test widget & UI rendering
├── DECISIONS.md                     # Catatan keputusan arsitektural PRD
└── env.example.json                 # Template variabel env Supabase
```

---

## 🧪 Pengujian & Kualitas Kode

Jalankan pemeriksaan lint dan analisa kode:
```bash
flutter analyze
```

Jalankan seluruh pengujian unit & widget:
```bash
flutter test
```

Menjalankan aplikasi di emulator atau perangkat:
```bash
flutter run
```
