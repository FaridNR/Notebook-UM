import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../data/initial_courses_data.dart';

/// DatabaseHelper: Lapisan infrastruktur SQLite level rendah (sqflite)
/// Bertanggung jawab atas koneksi database, inisialisasi DDL, dan factory FFI.
class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _db;

  DatabaseHelper._();

  static DatabaseHelper get instance => _instance ??= DatabaseHelper._();

  static bool _factoryInitialized = false;

  /// Inisialisasi database factory untuk lingkungan Desktop dan unit test FFI
  static void setupDatabaseFactory({bool noIsolate = false}) {
    if (_factoryInitialized && !noIsolate) return;
    if (!kIsWeb && (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      sqfliteFfiInit();
      databaseFactory = noIsolate ? databaseFactoryFfiNoIsolate : databaseFactoryFfi;
    }
    _factoryInitialized = true;
  }

  /// Mengembalikan instance Database SQLite yang aktif
  Future<Database> get database async {
    if (_db != null && _db!.isOpen) {
      return _db!;
    }
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb([String? customPath]) async {
    setupDatabaseFactory();

    String dbPath;
    if (customPath != null) {
      dbPath = customPath;
    } else if (kIsWeb) {
      dbPath = 'notebook_um.db';
    } else {
      final databasesPath = await getDatabasesPath();
      dbPath = p.join(databasesPath, 'notebook_um.db');
    }

    final db = await openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE courses (
            id TEXT PRIMARY KEY,
            code TEXT NOT NULL,
            name TEXT NOT NULL,
            lecturer TEXT NOT NULL,
            sks INTEGER NOT NULL,
            tone TEXT NOT NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE schedule_slots (
            id TEXT PRIMARY KEY,
            course_id TEXT NOT NULL,
            course_code TEXT NOT NULL,
            course_name TEXT NOT NULL,
            day INTEGER NOT NULL,
            day_name TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL,
            room TEXT NOT NULL,
            duration_minutes INTEGER NOT NULL,
            is_completed INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE CASCADE
          );
        ''');

        await db.execute('''
          CREATE TABLE tasks (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            notes TEXT NOT NULL DEFAULT '',
            course_id TEXT,
            course_code TEXT NOT NULL,
            course_name TEXT NOT NULL,
            priority TEXT NOT NULL,
            due_category TEXT NOT NULL,
            due_mode TEXT NOT NULL,
            due_at TEXT,
            created_at TEXT,
            due_text TEXT NOT NULL,
            secondary_meta TEXT,
            is_completed INTEGER NOT NULL DEFAULT 0,
            completed_note TEXT,
            reminder_enabled INTEGER NOT NULL DEFAULT 1,
            FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE SET NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          );
        ''');

        // Indeks performa kueri
        await db.execute('CREATE INDEX idx_slots_course ON schedule_slots (course_id);');
        await db.execute('CREATE INDEX idx_slots_day ON schedule_slots (day, start_time);');
        await db.execute('CREATE INDEX idx_tasks_due ON tasks (due_at, is_completed);');
        await db.execute('CREATE INDEX idx_tasks_course ON tasks (course_id);');

        // Seed 8 mata kuliah awal & jadwal resmi ke SQLite saat instalasi baru
        for (final course in initialCoursesData) {
          await db.insert('courses', {
            'id': course.id,
            'code': course.code,
            'name': course.name,
            'lecturer': course.lecturer,
            'sks': course.sks,
            'tone': course.tone.name,
          });
          for (final slot in course.slots) {
            await db.insert('schedule_slots', {
              'id': slot.id,
              'course_id': course.id,
              'course_code': slot.courseCode,
              'course_name': slot.courseName,
              'day': slot.day,
              'day_name': slot.dayName,
              'start_time': slot.startTime,
              'end_time': slot.endTime,
              'room': slot.room,
              'duration_minutes': slot.durationMinutes,
              'is_completed': slot.isCompleted ? 1 : 0,
            });
          }
        }

        // Seed default profile settings ke SQLite
        for (final entry in defaultProfileSettings.entries) {
          await db.insert(
            'settings',
            {'key': entry.key, 'value': entry.value},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      },
      onOpen: (db) async {
        // Migration check untuk database yang sudah ada
        final seededResult = await db.query(
          'settings',
          where: 'key = ?',
          whereArgs: ['is_seeded'],
        );
        if (seededResult.isEmpty) {
          final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM courses'),
          ) ?? 0;
          if (count == 0) {
            for (final course in initialCoursesData) {
              await db.insert(
                'courses',
                {
                  'id': course.id,
                  'code': course.code,
                  'name': course.name,
                  'lecturer': course.lecturer,
                  'sks': course.sks,
                  'tone': course.tone.name,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              for (final slot in course.slots) {
                await db.insert(
                  'schedule_slots',
                  {
                    'id': slot.id,
                    'course_id': course.id,
                    'course_code': slot.courseCode,
                    'course_name': slot.courseName,
                    'day': slot.day,
                    'day_name': slot.dayName,
                    'start_time': slot.startTime,
                    'end_time': slot.endTime,
                    'room': slot.room,
                    'duration_minutes': slot.durationMinutes,
                    'is_completed': slot.isCompleted ? 1 : 0,
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            }
          }
          for (final entry in defaultProfileSettings.entries) {
            await db.insert(
              'settings',
              {'key': entry.key, 'value': entry.value},
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      },
    );

    try {
      (db as dynamic).doNotUseSynchronized = true;
    } catch (_) {}

    return db;
  }

  /// Inisialisasi basis data eksplisit (misal untuk testing inMemory)
  Future<void> init({String? path}) async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
    }
    _db = await _initDb(path);
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
