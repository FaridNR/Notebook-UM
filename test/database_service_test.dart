import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:notebook_um/core/database/database_service.dart';
import 'package:notebook_um/models/course.dart';
import 'package:notebook_um/models/schedule_slot.dart';
import 'package:notebook_um/models/task.dart';
import 'package:notebook_um/state/app_state.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    DatabaseService.setupDatabaseFactory();
  });

  group('DatabaseService Direct CRUD & Seed Tests', () {
    late DatabaseService dbService;

    setUp(() async {
      dbService = DatabaseService.instance;
      // Gunakan in-memory database unik untuk setiap test run
      await dbService.init(path: inMemoryDatabasePath);
    });

    tearDown(() async {
      await dbService.close();
    });

    test('0. DEFAULT SEED SQLITE: Saat database dibuat (instalasi baru), 8 mata kuliah & jadwal langsung ada di SQLite', () async {
      final courses = await dbService.getCourses();
      expect(courses.length, 8, reason: 'Database SQLite harus memuat 8 mata kuliah default IFB5J saat dibuat');

      final totalSks = courses.fold(0, (sum, c) => sum + c.sks);
      expect(totalSks, 23, reason: 'Total SKS 8 mata kuliah default harus 23 SKS');

      final totalSlots = courses.fold(0, (sum, c) => sum + c.slots.length);
      expect(totalSlots, 8, reason: 'Total slot jadwal awal harus 8 slot');

      final isSeeded = await dbService.isInitialSeeded();
      expect(isSeeded, isTrue, reason: 'Flag is_seeded harus bernilai 1 di settings');
    });

    test('1. CREATE & READ: Tambah mata kuliah kustom beserta slot jadwal ke SQLite', () async {
      const customCourse = Course(
        id: 'c-cloud',
        code: '111800',
        name: 'Komputasi Awan (Cloud Computing)',
        lecturer: 'Drs. Cloud Expert, M.Kom.',
        sks: 3,
        tone: CourseTone.emerald,
        slots: [
          ScheduleSlot(
            id: 'slot-cloud-1',
            courseId: 'c-cloud',
            courseCode: '111800',
            courseName: 'Komputasi Awan (Cloud Computing)',
            day: 4,
            dayName: 'Kamis',
            startTime: '20:30',
            endTime: '22:00',
            room: 'LAB CLOUD 202',
            durationMinutes: 90,
          ),
        ],
      );

      // Create
      await dbService.insertCourse(customCourse);

      // Read
      final courses = await dbService.getCourses();
      expect(courses.length, 9, reason: '8 default + 1 kustom = 9 mata kuliah');

      final readCourse = courses.firstWhere((c) => c.id == 'c-cloud');
      expect(readCourse.code, '111800');
      expect(readCourse.name, 'Komputasi Awan (Cloud Computing)');
      expect(readCourse.sks, 3);
      expect(readCourse.tone, CourseTone.emerald);
      expect(readCourse.slots.length, 1);
      expect(readCourse.slots.first.dayName, 'Kamis');
      expect(readCourse.slots.first.room, 'LAB CLOUD 202');
      expect(readCourse.slots.first.startTime, '20:30');
    });

    test('2. UPDATE & READ: Perubahan data mata kuliah dan slot jadwal di SQLite', () async {
      final initialCourses = await dbService.getCourses();
      final targetCourse = initialCourses.firstWhere((c) => c.id == 'course-111600');

      // Update Course
      final updatedCourse = targetCourse.copyWith(
        name: 'Teknologi Aplikasi Bergerak (Lanjut)',
        sks: 4,
        tone: CourseTone.emerald,
      );
      await dbService.updateCourse(updatedCourse);

      // Update Slot
      const updatedSlot = ScheduleSlot(
        id: 'slot-111600',
        courseId: 'course-111600',
        courseCode: '111600',
        courseName: 'Teknologi Aplikasi Bergerak (Lanjut)',
        day: 2,
        dayName: 'Selasa',
        startTime: '19:00',
        endTime: '21:00',
        room: 'LAB MOBILE 101',
        durationMinutes: 120,
      );
      await dbService.updateSlot(updatedSlot);

      // Verify Read
      final courses = await dbService.getCourses();
      final readUpdated = courses.firstWhere((c) => c.id == 'course-111600');
      expect(readUpdated.name, 'Teknologi Aplikasi Bergerak (Lanjut)');
      expect(readUpdated.sks, 4);
      expect(readUpdated.tone, CourseTone.emerald);
      expect(readUpdated.slots.first.dayName, 'Selasa');
      expect(readUpdated.slots.first.room, 'LAB MOBILE 101');
      expect(readUpdated.slots.first.durationMinutes, 120);
    });

    test('3. CRUD TUGAS: Create multi-task, Update status/tenggat, Delete task di SQLite', () async {
      // Create 3 tasks
      final task1 = CourseTask(
        id: 't-01',
        title: 'Tugas 1: ERD & Relasi',
        notes: 'Gunakan Crow Foot notation',
        courseCode: '111500',
        courseName: 'SMBD',
        priority: TaskPriority.high,
        dueCategory: TaskDueCategory.urgent,
        dueMode: DueMode.fixed,
        dueAt: DateTime(2026, 11, 10, 23, 59),
        dueText: '10 Nov, 23:59 WITA',
      );

      final task2 = CourseTask(
        id: 't-02',
        title: 'Tugas 2: Flutter Layout',
        notes: 'Responsive 320px-390px',
        courseCode: '111600',
        courseName: 'TAB',
        priority: TaskPriority.medium,
        dueCategory: TaskDueCategory.upcoming,
        dueMode: DueMode.nextSession,
        dueText: 'Next Session',
      );

      final task3 = CourseTask(
        id: 't-03',
        title: 'Tugas 3: Ringkasan Paper',
        courseCode: '000800',
        courseName: 'PPI',
        priority: TaskPriority.low,
        dueCategory: TaskDueCategory.upcoming,
        dueMode: DueMode.none,
        dueText: 'Tanpa Tenggat',
      );

      await dbService.insertTask(task1);
      await dbService.insertTask(task2);
      await dbService.insertTask(task3);

      var tasks = await dbService.getTasks();
      expect(tasks.length, 3);

      // UPDATE task 1: Selesai
      final task1Updated = task1.copyWith(
        isCompleted: true,
        completedNote: 'Sudah submit di e-learning',
      );
      await dbService.updateTask(task1Updated);

      // UPDATE task 2: Ubah judul dan prioritas
      final task2Updated = task2.copyWith(
        title: 'Tugas 2: Flutter Layout & State',
        priority: TaskPriority.high,
      );
      await dbService.updateTask(task2Updated);

      tasks = await dbService.getTasks();
      final readT1 = tasks.firstWhere((t) => t.id == 't-01');
      final readT2 = tasks.firstWhere((t) => t.id == 't-02');
      expect(readT1.isCompleted, isTrue);
      expect(readT1.completedNote, 'Sudah submit di e-learning');
      expect(readT2.title, 'Tugas 2: Flutter Layout & State');
      expect(readT2.priority, TaskPriority.high);

      // DELETE task 3
      await dbService.deleteTask('t-03');
      tasks = await dbService.getTasks();
      expect(tasks.length, 2);
      expect(tasks.any((t) => t.id == 't-03'), isFalse);
    });

    test('4. CASCADE DELETE: Hapus matkul otomatis menghapus slot & mengalihkan tugas ke Mandiri', () async {
      // Pasang tugas ke mata kuliah Kriptografi (course-110700)
      final task = CourseTask(
        id: 'task-krip-rot13',
        title: 'Implementasi ROT13 & Vigenere',
        courseId: 'course-110700',
        courseCode: '110700',
        courseName: 'Kriptografi',
        priority: TaskPriority.high,
        dueCategory: TaskDueCategory.urgent,
        dueMode: DueMode.nextSession,
        dueText: 'Rabu, 20:30 WITA',
      );
      await dbService.insertTask(task);

      // Hapus Mata Kuliah Kriptografi
      await dbService.deleteCourse('course-110700');

      // Verifikasi Course terhapus dari 8 menjadi 7
      final courses = await dbService.getCourses();
      expect(courses.length, 7);
      expect(courses.any((c) => c.id == 'course-110700'), isFalse);

      // Verifikasi slot Kriptografi terhapus otomatis (cascade)
      final allSlots = [for (final c in courses) ...c.slots];
      expect(allSlots.any((s) => s.courseId == 'course-110700'), isFalse);

      // Verifikasi Tugas dialihkan ke MANDIRI dan dueMode menjadi fixed (PRD Rule)
      final tasks = await dbService.getTasks();
      expect(tasks.length, 1);
      final preservedTask = tasks.first;
      expect(preservedTask.id, 'task-krip-rot13');
      expect(preservedTask.courseId, isNull);
      expect(preservedTask.courseCode, 'MANDIRI');
      expect(preservedTask.courseName, 'Mandiri');
      expect(preservedTask.dueMode, DueMode.fixed);
    });

    test('5. CLEAR ALL DATA: Menghapus bersih seluruh tabel tapi tidak menghapus flag is_seeded', () async {
      await dbService.clearAllData();

      expect((await dbService.getCourses()).isEmpty, isTrue);
      expect((await dbService.getTasks()).isEmpty, isTrue);

      final isSeeded = await dbService.isInitialSeeded();
      expect(isSeeded, isTrue, reason: 'Flag is_seeded harus tetap ada agar tidak re-seed otomatis');
    });
  });

  group('AppState + SQLite Lifecycle & Persistence Simulation Tests', () {
    test('6. SIMULASI INSTAL, HAPUS, & RESTART APLIKASI: Data yang dihapus tetap hilang di SQLite saat app di-run lagi', () async {
      // Buat file database sementara di disk sistem untuk simulasi riil
      final tempDir = await Directory.systemTemp.createTemp('notebook_um_lifecycle_test_');
      final testDbPath = '${tempDir.path}/test_notebook.db';
      final dbService = DatabaseService.instance;

      try {
        await dbService.init(path: testDbPath);

        // --- SESI 1: PENGGUNA BARU MENGINSTAL & MEMBUKA APLIKASI ---
        final appStateSession1 = AppState(dbService: dbService);
        await appStateSession1.loadDbFuture;

        // Verifikasi awal: 8 mata kuliah bawaan IFB5J & Profil Mahasiswa langsung ada dari SQLite
        expect(appStateSession1.courses.length, 8, reason: 'Saat instal, data 8 mata kuliah langsung ada di SQLite');
        expect(appStateSession1.courses.any((c) => c.id == 'course-110700'), isTrue, reason: 'Kriptografi ada di awal');
        expect(appStateSession1.displayName, 'Farid Noor Rahman', reason: 'Profil tersimpan di SQLite settings');
        expect(appStateSession1.nim, '2411001');
        expect(appStateSession1.prodi, 'S1 Informatika • IFB5J');
        expect(appStateSession1.campus, 'Universitas Mulia');

        // Pengguna memperbarui profil di SQLite
        appStateSession1.updateProfile(displayName: 'Farid NR, S.Kom.');

        // Pengguna menambah 1 catatan tugas baru
        final newTask = CourseTask(
          id: 'task-persisted-real',
          title: 'Praktikum Normalisasi Database 3NF',
          notes: 'Dikerjakan dengan DB Browser SQLite',
          courseId: 'course-111500',
          courseCode: '111500',
          courseName: 'Sistem Manajemen Basis Data',
          priority: TaskPriority.high,
          dueCategory: TaskDueCategory.urgent,
          dueMode: DueMode.fixed,
          dueAt: DateTime(2026, 11, 8, 23, 59),
          dueText: '8 Nov, 23:59 WITA',
        );
        appStateSession1.addTask(newTask);

        // PENGGUNA MENGHAPUS MATA KULIAH KRIPTOGRAFI (course-110700)
        appStateSession1.deleteCourse('course-110700');
        expect(appStateSession1.courses.length, 7, reason: 'Sesi 1: Tersisa 7 mata kuliah setelah Kriptografi dihapus');
        expect(appStateSession1.courses.any((c) => c.id == 'course-110700'), isFalse);

        // PENGGUNA MENGHAPUS 1 SLOT JADWAL DARI SMBD (slot-111500)
        appStateSession1.deleteSlot('course-111500', 'slot-111500');
        final smbdCourse = appStateSession1.courses.firstWhere((c) => c.id == 'course-111500');
        expect(smbdCourse.slots.isEmpty, isTrue, reason: 'Slot SMBD berhasil dihapus');

        // Tunggu sesaat agar unawaited async writes tuntas ke disk
        await Future.delayed(const Duration(milliseconds: 300));

        // --- SIMULASI KELUAR DARI APLIKASI (KILL APP / RESTART) ---
        appStateSession1.dispose();

        // --- SESI 2: PENGGUNA MEMBUKA KEMBALI APLIKASI (RUN LAGI) ---
        // Sesi baru membaca database SQLite yang sama
        final appStateSession2 = AppState(dbService: dbService);
        await appStateSession2.loadDbFuture;

        // VERIFIKASI KUNCI:
        // 1. Mata kuliah Kriptografi yang sudah dihapus TETAP HILANG (tidak muncul lagi dari memory/re-seed!)
        expect(appStateSession2.courses.length, 7, reason: 'Saat app di-run lagi, jumlah matkul tetap 7');
        expect(appStateSession2.courses.any((c) => c.id == 'course-110700'), isFalse, reason: 'Kriptografi tetap hilang');

        // 2. Slot jadwal SMBD yang dihapus TETAP HILANG
        final restoredSmbd = appStateSession2.courses.firstWhere((c) => c.id == 'course-111500');
        expect(restoredSmbd.slots.isEmpty, isTrue, reason: 'Slot SMBD tetap hilang saat app di-run lagi');

        // 3. Tugas yang ditambahkan tetap tersimpan utuh
        expect(appStateSession2.tasks.length, 1);
        final restoredTask = appStateSession2.tasks.first;
        expect(restoredTask.id, 'task-persisted-real');
        expect(restoredTask.title, 'Praktikum Normalisasi Database 3NF');

        // 4. Profil yang diperbarui tetap tersimpan utuh di SQLite
        expect(appStateSession2.displayName, 'Farid NR, S.Kom.');
        expect(appStateSession2.nim, '2411001');
        expect(appStateSession2.campus, 'Universitas Mulia');

        // --- SESI 3: HAPUS SELURUH DATA & RESTART APLIKASI ---
        appStateSession2.clearAllData();
        await Future.delayed(const Duration(milliseconds: 300));
        appStateSession2.dispose();

        final appStateSession3 = AppState(dbService: dbService);
        await appStateSession3.loadDbFuture;

        // Verifikasi: Data tetap kosong, TIDAK otomatis re-seed karena is_seeded = 1
        expect(appStateSession3.courses.isEmpty, isTrue, reason: 'Setelah clearAllData, data tetap bersih saat di-run lagi');
        expect(appStateSession3.tasks.isEmpty, isTrue);

        appStateSession3.dispose();
      } finally {
        await dbService.close();
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });

    test('7. FITUR MATKUL TETAP: Simpan matkul tetap, hapus seluruh matkul, dan reset jadwal mengembalikan matkul tetap yang disimpan', () async {
      final dbService = DatabaseService.instance;
      await dbService.init(path: inMemoryDatabasePath);

      final appState = AppState(dbService: dbService);
      await appState.loadDbFuture;

      // 1. Simpan 8 matkul awal sebagai matkul tetap
      await appState.saveCurrentCoursesAsPermanent();

      // 2. Hapus seluruh matkul
      await appState.deleteAllCourses();
      expect(appState.courses.isEmpty, isTrue, reason: 'Seluruh mata kuliah berhasil dihapus');
      expect(appState.totalCourses, 0);

      // Verifikasi di SQLite courses benar-benar kosong
      final dbCoursesAfterDelete = await dbService.getCourses();
      expect(dbCoursesAfterDelete.isEmpty, isTrue);

      // 3. Reset jadwal ke matkul tetap yang disimpan
      await appState.resetToSavedPermanentCourses();

      // Verifikasi 8 matkul kembali pulih dari template tetap
      expect(appState.courses.length, 8, reason: 'Reset jadwal berhasil memulihkan 8 matkul tetap');
      expect(appState.totalSks, 23);

      final dbCoursesRestored = await dbService.getCourses();
      expect(dbCoursesRestored.length, 8);

      appState.dispose();
      await dbService.close();
    });
  });
}
