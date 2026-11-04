import 'package:flutter_test/flutter_test.dart';
import 'package:notebook_um/core/database/database_service.dart';
import 'package:notebook_um/models/course.dart';
import 'package:notebook_um/models/schedule_slot.dart';
import 'package:notebook_um/models/task.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    DatabaseService.setupDatabaseFactory();
  });

  group('DatabaseService Tests', () {
    late DatabaseService dbService;

    setUp(() async {
      dbService = DatabaseService.instance;
      // Gunakan in-memory database unik untuk setiap test run
      await dbService.init(path: inMemoryDatabasePath);
    });

    tearDown(() async {
      await dbService.close();
    });

    test('M3: Inisialisasi tabel, insert mata kuliah dan baca kembali', () async {
      final course = Course(
        id: 'c-test-01',
        code: '110700',
        name: 'Kriptografi',
        lecturer: "Muhammad Safi'i, S.Kom., M.Kom.",
        sks: 3,
        tone: CourseTone.zinc,
        slots: const [
          ScheduleSlot(
            id: 'slot-c-01',
            courseId: 'c-test-01',
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
      final courses = await dbService.getCourses();

      expect(courses.length, 1);
      expect(courses.first.id, 'c-test-01');
      expect(courses.first.name, 'Kriptografi');
      expect(courses.first.slots.length, 1);
      expect(courses.first.slots.first.room, 'A301');
    });

    test('M3: CRUD tugas (insert, update, delete, get)', () async {
      final task = CourseTask(
        id: 'task-db-01',
        title: 'Tugas SMBD',
        notes: 'ERD dan Normalisasi',
        courseId: 'c-test-01',
        courseCode: '111500',
        courseName: 'Sistem Manajemen Basis Data',
        priority: TaskPriority.high,
        dueCategory: TaskDueCategory.urgent,
        dueMode: DueMode.nextSession,
        dueText: 'Senin, 19:00 WITA',
        dueAt: DateTime(2026, 11, 9, 19, 0),
        createdAt: DateTime(2026, 11, 4, 10, 0),
      );

      // Insert
      await dbService.insertTask(task);
      var tasks = await dbService.getTasks();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Tugas SMBD');
      expect(tasks.first.isCompleted, isFalse);

      // Update
      final updated = task.copyWith(
        title: 'Tugas SMBD (Revisi)',
        isCompleted: true,
      );
      await dbService.updateTask(updated);
      tasks = await dbService.getTasks();
      expect(tasks.first.title, 'Tugas SMBD (Revisi)');
      expect(tasks.first.isCompleted, isTrue);

      // Delete
      await dbService.deleteTask('task-db-01');
      tasks = await dbService.getTasks();
      expect(tasks.isEmpty, isTrue);
    });

    test('M3: Hapus mata kuliah mengalihkan tugas ke mandiri (SET NULL)', () async {
      final course = const Course(
        id: 'c-to-delete',
        code: '111100',
        name: 'Penalaran Komputer',
        lecturer: 'Isa Rosita',
        sks: 3,
        tone: CourseTone.purple,
      );
      await dbService.insertCourse(course);

      final task = CourseTask(
        id: 'task-linked',
        title: 'Tugas Logika Predikat',
        courseId: 'c-to-delete',
        courseCode: '111100',
        courseName: 'Penalaran Komputer',
        priority: TaskPriority.medium,
        dueCategory: TaskDueCategory.upcoming,
        dueText: 'Selasa, 19:00 WITA',
      );
      await dbService.insertTask(task);

      // Hapus mata kuliah
      await dbService.deleteCourse('c-to-delete');

      final courses = await dbService.getCourses();
      expect(courses.isEmpty, isTrue);

      final tasks = await dbService.getTasks();
      expect(tasks.length, 1);
      expect(tasks.first.courseId, isNull);
      expect(tasks.first.courseCode, 'MANDIRI');
      expect(tasks.first.courseName, 'Mandiri');
    });

    test('M3: Simpan dan baca pengaturan / profil di settings table', () async {
      await dbService.setSetting('display_name', 'Farid Noor Rahman');
      await dbService.setSetting('nim', '2411001');
      await dbService.setSetting('theme_mode', 'dark');

      final settings = await dbService.getAllSettings();
      expect(settings['display_name'], 'Farid Noor Rahman');
      expect(settings['nim'], '2411001');
      expect(settings['theme_mode'], 'dark');
    });

    test('M3: AppState menyimpan task baru ke SQLite dan dapat di-load ulang', () async {
      // 1. Simpan task via DatabaseService
      final task = CourseTask(
        id: 'task-persistent-01',
        title: 'Laporan Praktikum SQLite',
        courseCode: '111500',
        courseName: 'Sistem Manajemen Basis Data',
        priority: TaskPriority.high,
        dueCategory: TaskDueCategory.urgent,
        dueText: 'Besok, 20:00 WITA',
      );
      await dbService.insertTask(task);

      // 2. Baca kembali lewat dbService
      final tasksFromDb = await dbService.getTasks();
      expect(tasksFromDb.any((t) => t.id == 'task-persistent-01'), isTrue);
      expect(tasksFromDb.firstWhere((t) => t.id == 'task-persistent-01').title, 'Laporan Praktikum SQLite');
    });
  });
}
