import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../models/course.dart';
import '../../models/schedule_slot.dart';
import '../../models/task.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _db;

  DatabaseService._();

  static DatabaseService get instance => _instance ??= DatabaseService._();

  static bool _factoryInitialized = false;

  /// Initialize database factory for Desktop and test environments
  static void setupDatabaseFactory() {
    if (_factoryInitialized) return;
    if (!kIsWeb && (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _factoryInitialized = true;
  }

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

    return await openDatabase(
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

        // Indexes for performance
        await db.execute('CREATE INDEX idx_slots_course ON schedule_slots (course_id);');
        await db.execute('CREATE INDEX idx_slots_day ON schedule_slots (day, start_time);');
        await db.execute('CREATE INDEX idx_tasks_due ON tasks (due_at, is_completed);');
        await db.execute('CREATE INDEX idx_tasks_course ON tasks (course_id);');
      },
    );
  }

  /// Initialize database explicitly (e.g. for testing with inMemory or custom file)
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

  // --- Courses CRUD ---

  Future<List<Course>> getCourses() async {
    final db = await database;
    final courseRows = await db.query('courses', orderBy: 'code ASC');
    final slotRows = await db.query('schedule_slots', orderBy: 'day ASC, start_time ASC');

    // Group slots by course_id
    final Map<String, List<ScheduleSlot>> slotsByCourse = {};
    for (final row in slotRows) {
      final cId = row['course_id'] as String;
      slotsByCourse.putIfAbsent(cId, () => []);
      slotsByCourse[cId]!.add(
        ScheduleSlot(
          id: row['id'] as String,
          courseId: cId,
          courseCode: row['course_code'] as String,
          courseName: row['course_name'] as String,
          day: row['day'] as int,
          dayName: row['day_name'] as String,
          startTime: row['start_time'] as String,
          endTime: row['end_time'] as String,
          room: row['room'] as String,
          durationMinutes: row['duration_minutes'] as int,
          isCompleted: (row['is_completed'] as int) == 1,
        ),
      );
    }

    return courseRows.map((row) {
      final id = row['id'] as String;
      final toneStr = row['tone'] as String;
      final tone = CourseTone.values.firstWhere(
        (t) => t.name == toneStr,
        orElse: () => CourseTone.blue,
      );

      return Course(
        id: id,
        code: row['code'] as String,
        name: row['name'] as String,
        lecturer: row['lecturer'] as String,
        sks: row['sks'] as int,
        tone: tone,
        slots: slotsByCourse[id] ?? [],
      );
    }).toList();
  }

  Future<void> insertCourse(Course course) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
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
        await txn.insert(
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
    });
  }

  Future<void> updateCourse(Course course) async {
    final db = await database;
    await db.update(
      'courses',
      {
        'code': course.code,
        'name': course.name,
        'lecturer': course.lecturer,
        'sks': course.sks,
        'tone': course.tone.name,
      },
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  Future<void> deleteCourse(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      // With ON DELETE CASCADE enabled, schedule_slots are deleted automatically.
      // With ON DELETE SET NULL on tasks, task course_id becomes NULL.
      // We also update course_code and course_name for tasks to MANDIRI according to PRD
      await txn.update(
        'tasks',
        {
          'course_id': null,
          'course_code': 'MANDIRI',
          'course_name': 'Mandiri',
          'due_mode': 'fixed',
          'secondary_meta': 'Mandiri',
        },
        where: 'course_id = ?',
        whereArgs: [id],
      );
      await txn.delete('courses', where: 'id = ?', whereArgs: [id]);
    });
  }

  // --- Schedule Slots CRUD ---

  Future<void> insertSlot(ScheduleSlot slot) async {
    final db = await database;
    await db.insert(
      'schedule_slots',
      {
        'id': slot.id,
        'course_id': slot.courseId,
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

  Future<void> updateSlot(ScheduleSlot slot) async {
    final db = await database;
    await db.update(
      'schedule_slots',
      {
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
      where: 'id = ?',
      whereArgs: [slot.id],
    );
  }

  Future<void> deleteSlot(String slotId) async {
    final db = await database;
    await db.delete('schedule_slots', where: 'id = ?', whereArgs: [slotId]);
  }

  // --- Tasks CRUD ---

  Future<List<CourseTask>> getTasks() async {
    final db = await database;
    final rows = await db.query('tasks', orderBy: 'rowid DESC');
    return rows.map((row) {
      final priorityStr = row['priority'] as String;
      final priority = TaskPriority.values.firstWhere(
        (p) => p.name == priorityStr,
        orElse: () => TaskPriority.medium,
      );

      final dueCategoryStr = row['due_category'] as String;
      final dueCategory = TaskDueCategory.values.firstWhere(
        (d) => d.name == dueCategoryStr,
        orElse: () => TaskDueCategory.upcoming,
      );

      final dueModeStr = row['due_mode'] as String;
      final dueMode = DueMode.values.firstWhere(
        (m) => m.name == dueModeStr,
        orElse: () => DueMode.none,
      );

      final dueAtStr = row['due_at'] as String?;
      final createdAtStr = row['created_at'] as String?;

      return CourseTask(
        id: row['id'] as String,
        title: row['title'] as String,
        notes: (row['notes'] as String?) ?? '',
        courseId: row['course_id'] as String?,
        courseCode: row['course_code'] as String,
        courseName: row['course_name'] as String,
        priority: priority,
        dueCategory: dueCategory,
        dueMode: dueMode,
        dueAt: dueAtStr != null ? DateTime.tryParse(dueAtStr) : null,
        createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr) : null,
        dueText: row['due_text'] as String,
        secondaryMeta: row['secondary_meta'] as String?,
        isCompleted: (row['is_completed'] as int) == 1,
        completedNote: row['completed_note'] as String?,
        reminderEnabled: (row['reminder_enabled'] as int? ?? 1) == 1,
      );
    }).toList();
  }

  Future<void> insertTask(CourseTask task) async {
    final db = await database;
    String? validCourseId = task.courseId;
    if (validCourseId != null) {
      final exists = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM courses WHERE id = ?', [validCourseId]),
      );
      if ((exists ?? 0) == 0) {
        validCourseId = null;
      }
    }

    await db.insert(
      'tasks',
      {
        'id': task.id,
        'title': task.title,
        'notes': task.notes,
        'course_id': validCourseId,
        'course_code': task.courseCode,
        'course_name': task.courseName,
        'priority': task.priority.name,
        'due_category': task.dueCategory.name,
        'due_mode': task.dueMode.name,
        'due_at': task.dueAt?.toIso8601String(),
        'created_at': task.createdAt?.toIso8601String(),
        'due_text': task.dueText,
        'secondary_meta': task.secondaryMeta,
        'is_completed': task.isCompleted ? 1 : 0,
        'completed_note': task.completedNote,
        'reminder_enabled': task.reminderEnabled ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTask(CourseTask task) async {
    final db = await database;
    String? validCourseId = task.courseId;
    if (validCourseId != null) {
      final exists = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM courses WHERE id = ?', [validCourseId]),
      );
      if ((exists ?? 0) == 0) {
        validCourseId = null;
      }
    }

    await db.update(
      'tasks',
      {
        'title': task.title,
        'notes': task.notes,
        'course_id': validCourseId,
        'course_code': task.courseCode,
        'course_name': task.courseName,
        'priority': task.priority.name,
        'due_category': task.dueCategory.name,
        'due_mode': task.dueMode.name,
        'due_at': task.dueAt?.toIso8601String(),
        'created_at': task.createdAt?.toIso8601String(),
        'due_text': task.dueText,
        'secondary_meta': task.secondaryMeta,
        'is_completed': task.isCompleted ? 1 : 0,
        'completed_note': task.completedNote,
        'reminder_enabled': task.reminderEnabled ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String taskId) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  // --- Settings / Profile Key-Value ---

  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final rows = await db.query('settings');
    final Map<String, String> result = {};
    for (final r in rows) {
      result[r['key'] as String] = r['value'] as String;
    }
    return result;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Maintenance & Bulk ---

  Future<bool> hasCourses() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM courses'));
    return (count ?? 0) > 0;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('tasks');
      await txn.delete('schedule_slots');
      await txn.delete('courses');
    });
  }

  Future<void> seedInitialCourses(List<Course> courses) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final course in courses) {
        await txn.insert(
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
          await txn.insert(
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
    });
  }
}
