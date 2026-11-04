import 'dart:io';
import 'package:flutter/material.dart';
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

  group('DatabaseService Direct CRUD Tests', () {
    late DatabaseService dbService;

    setUp(() async {
      dbService = DatabaseService.instance;
      // Gunakan in-memory database unik untuk setiap test run
      await dbService.init(path: inMemoryDatabasePath);
    });

    tearDown(() async {
      await dbService.close();
    });

    test('1. CREATE & READ: Mata kuliah beserta slot jadwal bertingkat', () async {
      final course = Course(
        id: 'c-smbd',
        code: '111500',
        name: 'Sistem Manajemen Basis Data',
        lecturer: 'Nasruddin Bin Idris, S.Kom., M.Kom.',
        sks: 3,
        tone: CourseTone.amber,
        slots: const [
          ScheduleSlot(
            id: 'slot-smbd-1',
            courseId: 'c-smbd',
            courseCode: '111500',
            courseName: 'Sistem Manajemen Basis Data',
            day: 1,
            dayName: 'Senin',
            startTime: '19:00',
            endTime: '20:30',
            room: 'LAB B (FIKOM)',
            durationMinutes: 90,
          ),
          ScheduleSlot(
            id: 'slot-smbd-2',
            courseId: 'c-smbd',
            courseCode: '111500',
            courseName: 'Sistem Manajemen Basis Data',
            day: 4,
            dayName: 'Kamis',
            startTime: '19:00',
            endTime: '20:30',
            room: 'LAB B (FIKOM)',
            durationMinutes: 90,
          ),
        ],
      );

      // Create
      await dbService.insertCourse(course);

      // Read
      final courses = await dbService.getCourses();
      expect(courses.length, 1);
      final readCourse = courses.first;
      expect(readCourse.id, 'c-smbd');
      expect(readCourse.code, '111500');
      expect(readCourse.sks, 3);
      expect(readCourse.tone, CourseTone.amber);
      expect(readCourse.slots.length, 2);
      expect(readCourse.slots[0].dayName, 'Senin');
      expect(readCourse.slots[1].dayName, 'Kamis');
    });

    test('2. UPDATE & READ: Perubahan data mata kuliah dan slot jadwal', () async {
      final course = Course(
        id: 'c-tab',
        code: '111600',
        name: 'Teknologi Aplikasi Bergerak',
        lecturer: 'Istia Budi, S.T., M.M.',
        sks: 3,
        tone: CourseTone.blue,
        slots: const [
          ScheduleSlot(
            id: 'slot-tab-1',
            courseId: 'c-tab',
            courseCode: '111600',
            courseName: 'Teknologi Aplikasi Bergerak',
            day: 1,
            dayName: 'Senin',
            startTime: '20:30',
            endTime: '22:00',
            room: 'LAB A (FIKOM)',
            durationMinutes: 90,
          ),
        ],
      );
      await dbService.insertCourse(course);

      // Update Course
      final updatedCourse = course.copyWith(
        name: 'Teknologi Aplikasi Bergerak (Lanjut)',
        sks: 4,
        tone: CourseTone.emerald,
      );
      await dbService.updateCourse(updatedCourse);

      // Update Slot
      const updatedSlot = ScheduleSlot(
        id: 'slot-tab-1',
        courseId: 'c-tab',
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
      expect(courses.first.name, 'Teknologi Aplikasi Bergerak (Lanjut)');
      expect(courses.first.sks, 4);
      expect(courses.first.tone, CourseTone.emerald);
      expect(courses.first.slots.first.dayName, 'Selasa');
      expect(courses.first.slots.first.room, 'LAB MOBILE 101');
      expect(courses.first.slots.first.durationMinutes, 120);
    });

    test('3. CRUD TUGAS: Create multi-task, Update status/tenggat, Delete task', () async {
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
      final course = Course(
        id: 'c-krip',
        code: '110700',
        name: 'Kriptografi',
        lecturer: "Muhammad Safi'i",
        sks: 3,
        tone: CourseTone.zinc,
        slots: const [
          ScheduleSlot(
            id: 'slot-krip-1',
            courseId: 'c-krip',
            courseCode: '110700',
            courseName: 'Kriptografi',
            day: 3,
            dayName: 'Rabu',
            startTime: '20:30',
            endTime: '22:00',
            room: 'A301',
            durationMinutes: 90,
          ),
        ],
      );
      await dbService.insertCourse(course);

      final task = CourseTask(
        id: 'task-krip-rot13',
        title: 'Implementasi ROT13 & Vigenere',
        courseId: 'c-krip',
        courseCode: '110700',
        courseName: 'Kriptografi',
        priority: TaskPriority.high,
        dueCategory: TaskDueCategory.urgent,
        dueMode: DueMode.nextSession,
        dueText: 'Rabu, 20:30 WITA',
      );
      await dbService.insertTask(task);

      // Hapus Mata Kuliah
      await dbService.deleteCourse('c-krip');

      // Verifikasi Course terhapus
      final courses = await dbService.getCourses();
      expect(courses.isEmpty, isTrue);

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

    test('5. CLEAR ALL DATA: Menghapus bersih seluruh tabel', () async {
      await dbService.insertCourse(
        const Course(
          id: 'c-1',
          code: '111',
          name: 'MK Test',
          lecturer: 'Dosen Test',
          sks: 2,
          tone: CourseTone.blue,
        ),
      );
      await dbService.insertTask(
        CourseTask(
          id: 't-1',
          title: 'Tugas Test',
          courseCode: '111',
          courseName: 'MK Test',
          priority: TaskPriority.medium,
          dueCategory: TaskDueCategory.upcoming,
          dueText: 'Besok',
        ),
      );

      await dbService.clearAllData();

      expect((await dbService.getCourses()).isEmpty, isTrue);
      expect((await dbService.getTasks()).isEmpty, isTrue);
    });
  });

  group('AppState + SQLite Lifecycle & Persistence Simulation Tests', () {
    test('6. SIMULASI KELUAR & BUKA LAGI APLIKASI: Data tetap tersimpan utuh di SQLite', () async {
      // Buat file database sementara di disk sistem
      final tempDir = await Directory.systemTemp.createTemp('notebook_um_test_');
      final testDbPath = '${tempDir.path}/test_notebook.db';
      final dbService = DatabaseService.instance;

      try {
        await dbService.init(path: testDbPath);

        // --- SESI 1: Buka aplikasi pertama kali ---
        final appStateSession1 = AppState(dbService: dbService);
        // Tunggu hidrasi database awal
        await Future.delayed(const Duration(milliseconds: 300));

        // Tambah catatan tugas baru
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

        // Tambah 1 mata kuliah baru
        const newCourse = Course(
          id: 'course-ai-custom',
          code: '111999',
          name: 'Kecerdasan Buatan Terapan',
          lecturer: 'Dr. AI Specialist, M.Kom.',
          sks: 3,
          tone: CourseTone.emerald,
          slots: [
            ScheduleSlot(
              id: 'slot-ai-1',
              courseId: 'course-ai-custom',
              courseCode: '111999',
              courseName: 'Kecerdasan Buatan Terapan',
              day: 6,
              dayName: 'Sabtu',
              startTime: '09:00',
              endTime: '11:30',
              room: 'LAB AI 401',
              durationMinutes: 150,
            ),
          ],
        );
        appStateSession1.addCourse(newCourse);

        // Ubah pengaturan profil dan tema
        appStateSession1.updateProfile(displayName: 'Farid Noor Rahman, S.Kom.');
        appStateSession1.toggleTheme(); // Jadi Dark Mode

        // Tunggu beberapa saat agar unawaited SQLite writes tuntas
        await Future.delayed(const Duration(milliseconds: 500));

        // --- SIMULASI KELUAR DARI APLIKASI (KILL APP) ---
        appStateSession1.dispose();

        // --- SESI 2: Pengguna membuka kembali NoteBook UM ---
        final appStateSession2 = AppState(dbService: dbService);
        // Tunggu hidrasi data SQLite
        await Future.delayed(const Duration(milliseconds: 500));

        // Verifikasi seluruh data sesi 1 tetap ada di sesi 2
        // A. Tugas
        expect(appStateSession2.tasks.length, 1);
        final restoredTask = appStateSession2.tasks.first;
        expect(restoredTask.id, 'task-persisted-real');
        expect(restoredTask.title, 'Praktikum Normalisasi Database 3NF');
        expect(restoredTask.notes, 'Dikerjakan dengan DB Browser SQLite');
        expect(restoredTask.priority, TaskPriority.high);

        // B. Mata Kuliah (8 default + 1 yang baru ditambahkan = 9)
        expect(appStateSession2.courses.length, 9);
        expect(appStateSession2.courses.any((c) => c.code == '111999'), isTrue);
        final restoredCourse = appStateSession2.courses.firstWhere((c) => c.code == '111999');
        expect(restoredCourse.name, 'Kecerdasan Buatan Terapan');
        expect(restoredCourse.slots.length, 1);
        expect(restoredCourse.slots.first.room, 'LAB AI 401');

        // C. Profil & Tema
        expect(appStateSession2.displayName, 'Farid Noor Rahman, S.Kom.');
        expect(appStateSession2.themeMode, ThemeMode.dark);

        appStateSession2.dispose();
      } finally {
        await dbService.close();
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });
  });
}
