import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../data/initial_courses_data.dart';
import '../../models/course.dart';
import '../../models/schedule_slot.dart';
import '../../models/task.dart';
import '../database/database_helper.dart';

/// Repository: Lapisan abstraksi data & kueri basis data
/// Menjembatani antara model domain (Course, Task, Slot) dengan eksekusi query SQLite.
class AppRepository {
  final DatabaseHelper _dbHelper;

  AppRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<Database> get _db => _dbHelper.database;

  // --- Courses CRUD ---

  Future<List<Course>> getCourses() async {
    final db = await _db;
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
    final db = await _db;
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
    final db = await _db;
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
    final db = await _db;
    await db.transaction((txn) async {
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

  Future<void> deleteAllCourses() async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update(
        'tasks',
        {
          'course_id': null,
          'course_code': 'MANDIRI',
          'course_name': 'Mandiri',
          'due_mode': 'fixed',
          'secondary_meta': 'Mandiri',
        },
      );
      await txn.delete('schedule_slots');
      await txn.delete('courses');
    });
  }

  // --- Permanent Course Presets ---

  Future<void> savePermanentCourses(List<Course> courses) async {
    final jsonStr = jsonEncode(courses.map((c) => c.toJson()).toList());
    await setSetting('saved_permanent_courses', jsonStr);
  }

  Future<List<Course>> getPermanentCourses() async {
    final settings = await getAllSettings();
    if (settings.containsKey('saved_permanent_courses')) {
      try {
        final raw = jsonDecode(settings['saved_permanent_courses']!) as List;
        final list = raw.map((item) => Course.fromJson(item as Map<String, dynamic>)).toList();
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    return initialCoursesData;
  }

  Future<void> resetToSavedPermanentCourses() async {
    final targetCourses = await getPermanentCourses();
    await clearAllData();
    await seedInitialCourses(targetCourses);
  }

  Future<void> resetToDefaultCourses() async {
    await clearAllData();
    await seedInitialCourses(initialCoursesData);
    final db = await _db;
    for (final entry in defaultProfileSettings.entries) {
      await db.insert(
        'settings',
        {'key': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // --- Schedule Slots CRUD ---

  Future<void> insertSlot(ScheduleSlot slot) async {
    final db = await _db;
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
    final db = await _db;
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
    final db = await _db;
    await db.delete('schedule_slots', where: 'id = ?', whereArgs: [slotId]);
  }

  // --- Tasks CRUD ---

  Future<List<CourseTask>> getTasks() async {
    final db = await _db;
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
    final db = await _db;
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
    final db = await _db;
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
    final db = await _db;
    await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  // --- Settings / Profile Key-Value ---

  Future<Map<String, String>> getAllSettings() async {
    final db = await _db;
    final rows = await db.query('settings');
    final Map<String, String> result = {};
    for (final r in rows) {
      result[r['key'] as String] = r['value'] as String;
    }
    return result;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await _db;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Maintenance & Seeding ---

  Future<bool> hasCourses() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM courses'));
    return (count ?? 0) > 0;
  }

  Future<bool> isInitialSeeded() async {
    final db = await _db;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['is_seeded'],
    );
    return rows.isNotEmpty && rows.first['value'] == '1';
  }

  Future<void> clearAllData() async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('tasks');
      await txn.delete('schedule_slots');
      await txn.delete('courses');
    });
  }

  Future<void> seedInitialCourses([List<Course>? courses]) async {
    final list = courses ?? initialCoursesData;
    final db = await _db;
    await db.transaction((txn) async {
      for (final course in list) {
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
      await txn.insert(
        'settings',
        {'key': 'is_seeded', 'value': '1'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }
}
