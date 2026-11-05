# NoteBook UM — Aplikasi Catatan Tugas & Jadwal Kuliah (MVP)

Aplikasi mobile Flutter untuk mahasiswa yang menghubungkan catatan tugas dengan jadwal kuliah secara *real-time*. Desain mengadopsi prinsip **NoteBook UM Anti-Slop Design System** (pemisahan ruang via *surface tone-steps*, tipografi alami tanpa *trailing periods*, dock navigasi berlekuk halus menempel di bawah, dan palet warna akademik beridentitas kuat).

Persistensi data didukung penuh secara luring (*offline-first*) menggunakan basis data lokal relasional **SQLite (sqflite)**, menjamin seluruh jadwal, catatan tugas, dan pengaturan profil tersimpan permanen di perangkat.

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
   - Data bawaan memuat 8 mata kuliah resmi IFB5J Universitas Mulia Semester Ganjil 2026 (23 SKS).

3. **Daftar Tugas & Filter Fleksibel**:
   - Pencarian instan berdasarkan judul tugas, catatan, atau nama mata kuliah.
   - Filter tab status: *Semua*, *Mendesak*, *Next Session*, *Mendatang*, *Selesai*.
   - *Filter rail* mata kuliah dinamis.
   - Modal detail tugas serta form **Ubah Tugas** (edit judul, deskripsi/catatan, tenggat waktu) dengan validasi interaktif.

4. **Pencatatan Tugas Cepat (`AddTaskSheet`)**:
   - Deteksi otomatis kelas yang sedang aktif atau terdekat.
   - 3 mode tenggat sesuai PRD:
     - **Next Session**: Tenggat dihitung otomatis ke jam mulai pertemuan kuliah berikutnya setelah `created_at`.
     - **Pilih Tanggal**: Pemilihan kalender tanggal dan jam spesifik.
     - **Tanpa Tenggat**: Tugas fleksibel tanpa batas waktu kaku.
   - Pemilihan prioritas (*Rendah*, *Sedang*, *Tinggi*) dan switch pengingat notifikasi lokal.

5. **Mata Kuliah & Beban Studi**:
   - Ringkasan beban studi semester (total SKS terhadap batas 24 SKS).
   - Tambah mata kuliah lengkap dengan kode, nama, dosen, SKS, dan warna identitas akademik.
   - **Simpan Matkul Tetap**: Menyimpan susunan mata kuliah dan jadwal saat ini ke SQLite sebagai template tetap kustom.
   - **Hapus Seluruh Matkul**: Menghapus seluruh mata kuliah dengan konfirmasi dialog aman (tugas terkait otomatis dialihkan ke mode *Mandiri*).
   - Modal kelola dan hapus per-matkul dengan aturan *cascade deletion* pada slot jadwal.

6. **Pengaturan, Profil & Manajemen Cadangan**:
   - Profil mahasiswa tersimpan di SQLite: Nama (Farid Noor Rahman), NIM (2411001), Program Studi (S1 Informatika • IFB5J), Kampus (Universitas Mulia), dan zona waktu (WITA).
   - Pengaturan sakelar pengingat H-24 dan H-1 jam.
   - Toggle tema *Light Mode* dan *Dark Mode (OLED Black)*.
   - **Reset Jadwal ke Matkul Tetap**: Memulihkan jadwal kuliah mengikuti template matkul tetap yang disimpan (atau 8 matkul default IFB5J) dengan dialog konfirmasi.
   - **Ekspor File JSON Lengkap**: Pencadangan seluruh data perkuliahan ke format JSON terstruktur.
   - Zona berbahaya penghapusan data dengan konfirmasi pengetikan kata **"HAPUS"**.

7. **Dock Navigasi Melengkung (Notched Curve) & Estetika Selaras**:
   - Bagian atas dock navigasi dibuat melengkung (*concave circular notch*) dengan `CustomPainter` yang mengikuti kontur lingkaran tombol Tugas di tengah secara presisi.
   - Tombol tengah Tugas diselaraskan dengan palet utama aplikasi: *Obsidian Black (`#090A0C`)* pada Light Mode dan *Ivory White (`#F4F4F5`)* pada Dark Mode.

---

## 💾 Arsitektur Berlapis (Layered Pattern) & Basis Data SQLite

Aplikasi beroperasi secara *offline-first* murni dengan pemisahan tanggung jawab yang tegas:
```
UI (Screens / Widgets)
       │
       ▼ (Meminta aksi / perubahan catatan)
ViewModel (AppState : ChangeNotifier)
       │
       ▼ (Menjalankan query & pemetaan domain)
Repository (AppRepository)
       │
       ▼ (Koneksi, DDL, lifecycle & driver sqflite)
DatabaseHelper (DatabaseHelper)
       │
       ▼
SQLite Database (Disk Persistence)
```

Alur Reaktivitas:
1. **UI** meminta aksi (misal ubah catatan, tambah tugas, kelola matkul) ke **ViewModel (`AppState`)**.
2. **ViewModel** meneruskan pemanggilan ke **Repository (`AppRepository`)**.
3. **Repository** mengeksekusi kueri transaksi ke basis data via **`DatabaseHelper` (sqflite)**.
4. **ViewModel** memuat ulang daftar data terbaru dari Repository dan memanggil `notifyListeners()`.
5. **UI** secara reaktif menerima notifikasi dan langsung memperbarui tampilan secara otomatis.

Struktur Tabel SQLite:
- **Tabel `courses`**: Menyimpan ID, kode mata kuliah, nama, dosen pengampu, bobot SKS, dan identitas warna (*tone*).
- **Tabel `schedule_slots`**: Menyimpan slot jadwal kuliah (hari, jam mulai, jam selesai, ruang kelas) dengan relasi `FOREIGN KEY (course_id) ON DELETE CASCADE`.
- **Tabel `tasks`**: Menyimpan seluruh catatan tugas, catatan progres, prioritas, status selesai, mode tenggat, dan `due_at`.
- **Tabel `settings`**: Penyimpanan kunci-nilai (*key-value*) untuk data profil, preferensi notifikasi, mode tema, flag *is_seeded*, dan template *saved_permanent_courses*.

---

## 🛠️ Struktur Proyek

```
/
├── lib/
│   ├── core/
│   │   ├── database/
│   │   │   ├── database_helper.dart    # DatabaseHelper (sqflite connection, schema, lifecycle, FFI)
│   │   │   └── database_service.dart   # Service adapter delegator
│   │   ├── repository/
│   │   │   └── app_repository.dart     # AppRepository (Query CRUD, domain mapping, transactions)
│   │   └── time/
│   │       └── time_service.dart       # Logika getClassStatus, calculateNextSession, zona WITA
│   ├── data/
│   │   └── initial_courses_data.dart   # Data awal 8 MK IFB5J & profil default mahasiswa
│   ├── models/
│   │   ├── course.dart                 # Model Mata Kuliah & identitas warna (toJson & fromJson)
│   │   ├── schedule_slot.dart          # Model Slot Jadwal mingguan (toJson & fromJson)
│   │   └── task.dart                   # Model Tugas & 3 mode tenggat
│   ├── state/
│   │   └── app_state.dart              # ViewModel (ChangeNotifier) terhubung ke AppRepository
│   ├── theme/
│   │   └── app_theme.dart              # Tone step colors & tema Material 3
│   ├── widgets/
│   │   ├── add_task_sheet.dart         # Modal sheet tambah tugas cepat
│   │   ├── course_badge.dart           # Badge kode matkul solid/outline
│   │   ├── dock_navigation.dart        # Notched bottom dock dengan lekukan kurva melengkung
│   │   ├── edit_task_sheet.dart        # Modal sheet edit judul, catatan, dan tenggat tugas
│   │   └── undo_toast.dart             # Bar undo 5 detik
│   ├── screens/
│   │   ├── about_screen.dart           # Layar Informasi Akademik & Pengembang
│   │   ├── auth_screen.dart            # Layar login & validasi password
│   │   ├── today_screen.dart           # Layar Hari Ini & live kelas aktif
│   │   ├── schedule_screen.dart        # Layar Jadwal mingguan
│   │   ├── tasks_screen.dart           # Layar Daftar tugas & filter status/matkul
│   │   ├── courses_screen.dart         # Layar Manajemen mata kuliah, simpan tetap & hapus semua
│   │   └── settings_screen.dart        # Layar Pengaturan, profil, reset jadwal & ekspor JSON
│   └── main.dart                       # Inisialisasi app, factory SQLite FFI & observer siklus hidup
├── test/
│   ├── database_service_test.dart      # Pengujian menyeluruh CRUD SQLite & simulasi kill/restart app
│   ├── time_logic_test.dart            # Unit test logika waktu, batas menit & next_session
│   └── widget_test.dart                # Widget test UI rendering & interaksi form
├── PRD — Aplikasi Catatan Tugas & Jadwal Kuliah (MVP).pdf # Dokumen spesifikasi PRD resmi
└── pubspec.yaml                        # Dependensi proyek (sqflite, sqflite_common_ffi, provider, intl)
```

---

## 🧪 Pengujian & Kualitas Kode

Jalankan pemeriksaan lint dan analisa kode (0 warning / clean):
```bash
flutter analyze
```

Jalankan seluruh rangkaian pengujian (29 tests passed 100%):
```bash
flutter test
```

Menjalankan aplikasi di emulator atau perangkat:
```bash
flutter run
```
