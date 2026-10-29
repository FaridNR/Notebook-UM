import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/time/time_service.dart';
import '../models/course.dart';
import '../models/schedule_slot.dart';
import '../models/task.dart';

class AppState extends ChangeNotifier {
  int _selectedTabIndex = 0;
  ThemeMode _themeMode = ThemeMode.light;

  String _taskSearchQuery = '';
  String _selectedStatusTab = 'Semua';
  String? _selectedCourseFilter; // null = Semua Matkul

  bool _isReminderH24 = true;
  bool _isReminderH1 = true;

  // Profile data (PRD Section 4.4 & 1.5 Flow F)
  String _displayName = 'Farid Noor Rahman';
  String _nim = '2411001';
  String _prodi = 'S1 Informatika • IFB5J';
  final String _campus = 'Universitas Mulia';
  String _timezone = 'Asia/Makassar';
  bool _isLoggedIn = true;

  // Live Time state (PRD Section 1.7)
  late DateTime _liveNow;
  Timer? _minuteTicker;

  // Undo Toast state
  bool _showUndoToast = false;
  String _undoToastMessage = '';
  int _undoCountdown = 5;
  Timer? _undoToastTimer;
  CourseTask? _lastToggledTask;

  List<Course> _courses = [];
  List<CourseTask> _tasks = [];

  int get selectedTabIndex => _selectedTabIndex;
  ThemeMode get themeMode => _themeMode;
  String get taskSearchQuery => _taskSearchQuery;
  String get selectedStatusTab => _selectedStatusTab;
  String? get selectedCourseFilter => _selectedCourseFilter;
  bool get isReminderH24 => _isReminderH24;
  bool get isReminderH1 => _isReminderH1;
  bool get showUndoToast => _showUndoToast;
  String get undoToastMessage => _undoToastMessage;
  int get undoCountdown => _undoCountdown;
  bool get canUndo => _lastToggledTask != null;
  String get displayName => _displayName;
  String get nim => _nim;
  String get prodi => _prodi;
  String get campus => _campus;
  String get timezone => _timezone;
  bool get isLoggedIn => _isLoggedIn;
  DateTime get liveNow => _liveNow;

  List<Course> get courses => _courses;
  List<CourseTask> get tasks => _tasks;

  // Computed statistics
  int get totalCourses => _courses.length;
  int get totalSks => _courses.fold(0, (sum, c) => sum + c.sks);
  int get totalSlots => _courses.fold(0, (sum, c) => sum + c.slots.length);
  int get activeTasksCount => _tasks.where((t) => !t.isCompleted).length;
  int get completedTasksCount => _tasks.where((t) => t.isCompleted).length;

  AppState() {
    _liveNow = TimeService.nowInWita();
    _startMinuteTicker();
    _initializeData();
  }

  void _startMinuteTicker() {
    _minuteTicker?.cancel();
    _minuteTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      _liveNow = TimeService.nowInWita();
      notifyListeners();
    });
  }

  /// Called on AppLifecycleState.resumed (PRD Section 1.7)
  void resumeTick() {
    _liveNow = TimeService.nowInWita();
    notifyListeners();
  }

  @override
  void dispose() {
    _minuteTicker?.cancel();
    _undoToastTimer?.cancel();
    super.dispose();
  }

  void _initializeData() {
    // 8 Mata Kuliah Aktif IFB5J Universitas Mulia Balikpapan (23 SKS Total)
    _courses = [
      const Course(
        id: 'course-111500',
        code: '111500',
        name: 'Sistem Manajemen Basis Data',
        lecturer: 'Nasruddin Bin Idris, S.Kom., M.Kom.',
        sks: 3,
        tone: CourseTone.amber,
        slots: [
          ScheduleSlot(
            id: 'slot-111500',
            courseId: 'course-111500',
            courseCode: '111500',
            courseName: 'Sistem Manajemen Basis Data',
            day: 1,
            dayName: 'Senin',
            startTime: '19:00',
            endTime: '20:30',
            room: 'LAB B (FIKOM)',
            durationMinutes: 90,
          ),
        ],
      ),
      const Course(
        id: 'course-111600',
        code: '111600',
        name: 'Teknologi Aplikasi Bergerak',
        lecturer: 'Istia Budi, S.T., M.M.',
        sks: 3,
        tone: CourseTone.blue,
        slots: [
          ScheduleSlot(
            id: 'slot-111600',
            courseId: 'course-111600',
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
      ),
      const Course(
        id: 'course-111100',
        code: '111100',
        name: 'Penalaran Komputer',
        lecturer: 'Isa Rosita, S.Kom., M.Cs.',
        sks: 3,
        tone: CourseTone.purple,
        slots: [
          ScheduleSlot(
            id: 'slot-111100',
            courseId: 'course-111100',
            courseCode: '111100',
            courseName: 'Penalaran Komputer',
            day: 2,
            dayName: 'Selasa',
            startTime: '19:00',
            endTime: '20:30',
            room: 'A201',
            durationMinutes: 90,
          ),
        ],
      ),
      const Course(
        id: 'course-111400',
        code: '111400',
        name: 'Simulasi dan Game Komputer',
        lecturer: 'Heruzulkifli Rowa, S.Kom, M.Kom',
        sks: 3,
        tone: CourseTone.emerald,
        slots: [
          ScheduleSlot(
            id: 'slot-111400',
            courseId: 'course-111400',
            courseCode: '111400',
            courseName: 'Simulasi dan Game Komputer',
            day: 2,
            dayName: 'Selasa',
            startTime: '20:30',
            endTime: '22:00',
            room: 'LAB A (FIKOM)',
            durationMinutes: 90,
          ),
        ],
      ),
      const Course(
        id: 'course-110700',
        code: '110700',
        name: 'Kriptografi',
        lecturer: "Muhammad Safi'i, S.Kom., M.Kom.",
        sks: 3,
        tone: CourseTone.zinc,
        slots: [
          ScheduleSlot(
            id: 'slot-110700',
            courseId: 'course-110700',
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
      ),
      const Course(
        id: 'course-000800',
        code: '000800',
        name: 'Penulisan dan Publikasi Ilmiah',
        lecturer: 'Yustian Servanda, S.Kom., M.Kom.',
        sks: 2,
        tone: CourseTone.blue,
        slots: [
          ScheduleSlot(
            id: 'slot-000800',
            courseId: 'course-000800',
            courseCode: '000800',
            courseName: 'Penulisan dan Publikasi Ilmiah',
            day: 4,
            dayName: 'Kamis',
            startTime: '19:00',
            endTime: '20:30',
            room: 'A203',
            durationMinutes: 90,
          ),
        ],
      ),
      const Course(
        id: 'course-110600',
        code: '110600',
        name: 'Jaringan Nirkabel',
        lecturer: 'Maradona, S.Kom., M.Kom.',
        sks: 3,
        tone: CourseTone.amber,
        slots: [
          ScheduleSlot(
            id: 'slot-110600',
            courseId: 'course-110600',
            courseCode: '110600',
            courseName: 'Jaringan Nirkabel',
            day: 5,
            dayName: 'Jumat',
            startTime: '19:00',
            endTime: '20:30',
            room: 'LAB JARINGAN (FIKOM)',
            durationMinutes: 90,
          ),
        ],
      ),
      const Course(
        id: 'course-111000',
        code: '111000',
        name: 'Pemrograman Aplikasi Bergerak',
        lecturer: 'Pramudya Prima Insan, S.Kom., M.Kom.',
        sks: 3,
        tone: CourseTone.emerald,
        slots: [
          ScheduleSlot(
            id: 'slot-111000',
            courseId: 'course-111000',
            courseCode: '111000',
            courseName: 'Pemrograman Aplikasi Bergerak',
            day: 5,
            dayName: 'Jumat',
            startTime: '20:30',
            endTime: '22:00',
            room: 'LAB A (FIKOM)',
            durationMinutes: 90,
          ),
        ],
      ),
    ];

    // Seluruh tugas dimulai kosong (tanpa data dummy)
    _tasks = [];
  }

  // Active session helper for TodayScreen
  ScheduleSlot? getActiveSlotToday() {
    final todaySlots = getTodaySlots();
    if (todaySlots.isEmpty) return null;

    // 1. Prioritaskan kelas yang sedang berlangsung real-time
    for (final slot in todaySlots) {
      final statusResult = TimeService.getClassStatus(_liveNow, slot);
      if (statusResult.status == ClassStatus.berlangsung) {
        return slot;
      }
    }

    // 2. Jika tidak ada yang berlangsung, pilih kelas mendatang berikutnya hari ini
    for (final slot in todaySlots) {
      final statusResult = TimeService.getClassStatus(_liveNow, slot);
      if (statusResult.status == ClassStatus.akanDatang) {
        return slot;
      }
    }

    // 3. Jika semua kelas hari ini telah selesai, tampilkan sesi terakhir hari ini
    return todaySlots.last;
  }

  List<ScheduleSlot> getTodaySlots() {
    final todayWeekday = _liveNow.weekday;
    final list = <ScheduleSlot>[];
    for (final course in _courses) {
      for (final slot in course.slots) {
        if (slot.day == todayWeekday) {
          list.add(slot);
        }
      }
    }
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  void setTabIndex(int index) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
      notifyListeners();
    }
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setTaskSearchQuery(String query) {
    _taskSearchQuery = query;
    notifyListeners();
  }

  void setStatusTab(String tab) {
    _selectedStatusTab = tab;
    notifyListeners();
  }

  void setCourseFilter(String? courseCode) {
    _selectedCourseFilter = courseCode;
    notifyListeners();
  }

  void updateProfile({String? displayName, String? nim, String? prodi, String? timezone}) {
    if (displayName != null) _displayName = displayName;
    if (nim != null) _nim = nim;
    if (prodi != null) _prodi = prodi;
    if (timezone != null) _timezone = timezone;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  void login(String email, String password) {
    _isLoggedIn = true;
    notifyListeners();
  }

  // Task Completion & Undo
  void toggleTaskCompletion(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final newStatus = !task.isCompleted;
      task.isCompleted = newStatus;
      _lastToggledTask = task;

      _undoToastMessage = newStatus ? '1 tugas ditandai selesai' : '1 tugas dibuka kembali';
      _showUndoToast = true;
      _undoCountdown = 5;

      _undoToastTimer?.cancel();
      _undoToastTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_undoCountdown > 1) {
          _undoCountdown--;
          notifyListeners();
        } else {
          _showUndoToast = false;
          _lastToggledTask = null;
          timer.cancel();
          _undoToastTimer = null;
          notifyListeners();
        }
      });

      notifyListeners();
    }
  }

  void undoLastAction() {
    if (_lastToggledTask != null) {
      final index = _tasks.indexWhere((t) => t.id == _lastToggledTask!.id);
      if (index != -1) {
        _tasks[index].isCompleted = !_tasks[index].isCompleted;
      }
      _lastToggledTask = null;
    }
    _showUndoToast = false;
    _undoToastTimer?.cancel();
    _undoToastTimer = null;
    notifyListeners();
  }

  void dismissUndoToast() {
    _showUndoToast = false;
    _lastToggledTask = null;
    _undoToastTimer?.cancel();
    _undoToastTimer = null;
    notifyListeners();
  }

  void showToast(String message) {
    _undoToastMessage = message;
    _showUndoToast = true;
    _lastToggledTask = null;
    _undoCountdown = 3;
    _undoToastTimer?.cancel();
    _undoToastTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_undoCountdown > 1) {
        _undoCountdown--;
        notifyListeners();
      } else {
        _showUndoToast = false;
        timer.cancel();
        _undoToastTimer = null;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  // --- Task CRUD ---
  void addTask(CourseTask newTask) {
    _tasks.insert(0, newTask);
    notifyListeners();
  }

  void updateTask(CourseTask updatedTask) {
    final idx = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (idx != -1) {
      _tasks[idx] = updatedTask;
      notifyListeners();
    }
  }

  void deleteTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    showToast('Tugas telah dihapus');
  }

  // --- Course CRUD ---
  void addCourse(Course course) {
    _courses.add(course);
    notifyListeners();
  }

  void updateCourse(Course updatedCourse) {
    final idx = _courses.indexWhere((c) => c.id == updatedCourse.id);
    if (idx != -1) {
      _courses[idx] = updatedCourse;
      _recalculateNextSessionTasks(updatedCourse.id);
      notifyListeners();
    }
  }

  /// PRD Section 4.3 rule:
  /// "Saat mata kuliah dihapus, tugas next_session miliknya diubah menjadi
  /// fixed dengan due_at terakhir, karena course_id menjadi null."
  void deleteCourse(String courseId) {
    _courses.removeWhere((c) => c.id == courseId);

    // Update tasks referencing this course
    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].courseId == courseId) {
        final t = _tasks[i];
        final newDueMode = (t.dueMode == DueMode.nextSession) ? DueMode.fixed : t.dueMode;
        _tasks[i] = t.copyWith(
          courseId: null,
          courseCode: 'MANDIRI',
          courseName: 'Mandiri',
          dueMode: newDueMode,
          secondaryMeta: 'Mandiri',
        );
      }
    }
    showToast('Mata kuliah dihapus, tugas dialihkan ke mandiri');
  }

  // --- Schedule Slots CRUD ---
  void addSlot(String courseId, ScheduleSlot slot) {
    final idx = _courses.indexWhere((c) => c.id == courseId);
    if (idx != -1) {
      final updatedSlots = List<ScheduleSlot>.from(_courses[idx].slots)..add(slot);
      _courses[idx] = _courses[idx].copyWith(slots: updatedSlots);
      _recalculateNextSessionTasks(courseId);
      notifyListeners();
    }
  }

  void updateSlot(String courseId, ScheduleSlot updatedSlot) {
    final idx = _courses.indexWhere((c) => c.id == courseId);
    if (idx != -1) {
      final updatedSlots = _courses[idx].slots.map((s) => s.id == updatedSlot.id ? updatedSlot : s).toList();
      _courses[idx] = _courses[idx].copyWith(slots: updatedSlots);
      _recalculateNextSessionTasks(courseId);
      notifyListeners();
    }
  }

  void deleteSlot(String courseId, String slotId) {
    final idx = _courses.indexWhere((c) => c.id == courseId);
    if (idx != -1) {
      final updatedSlots = _courses[idx].slots.where((s) => s.id != slotId).toList();
      _courses[idx] = _courses[idx].copyWith(slots: updatedSlots);
      _recalculateNextSessionTasks(courseId);
      notifyListeners();
    }
  }

  /// PRD Section 1.5 Flow D & Section 1.7:
  /// "Pengguna mengubah atau menghapus slot, lalu tenggat tugas next_session
  /// yang belum selesai dan belum lewat dihitung ulang. Tampilkan toast
  /// '2 tugas disesuaikan dengan jadwal baru'."
  void _recalculateNextSessionTasks(String courseId) {
    final course = getCourse(courseId);
    if (course == null) return;

    int adjustedCount = 0;
    final now = _liveNow;

    for (int i = 0; i < _tasks.length; i++) {
      final t = _tasks[i];
      if (t.courseId == courseId && t.dueMode == DueMode.nextSession && !t.isCompleted) {
        // If not expired
        if (t.dueAt == null || t.dueAt!.isAfter(now)) {
          final nextDue = TimeService.calculateNextSession(
            createdAt: t.createdAt ?? now,
            slots: course.slots,
          );

          if (nextDue != null) {
            _tasks[i] = t.copyWith(
              dueAt: nextDue,
              dueText: TimeService.formatNextSessionText(nextDue),
            );
            adjustedCount++;
          }
        }
      }
    }

    if (adjustedCount > 0) {
      showToast('$adjustedCount tugas disesuaikan dengan jadwal baru');
    }
  }

  void toggleReminderH24() {
    _isReminderH24 = !_isReminderH24;
    notifyListeners();
  }

  void toggleReminderH1() {
    _isReminderH1 = !_isReminderH1;
    notifyListeners();
  }

  void clearAllData() {
    _courses = [];
    _tasks = [];
    notifyListeners();
  }

  String exportDataAsJson() {
    final data = {
      'exported_at': DateTime.now().toIso8601String(),
      'timezone': _timezone,
      'user': {
        'name': _displayName,
        'nim': _nim,
        'prodi': _prodi,
        'campus': _campus,
        'email': 'farid.noor@mhs.universitasmulia.ac.id',
        'role': 'Mahasiswa',
      },
      'courses': _courses.map((c) => c.toJson()).toList(),
      'tasks': _tasks.map((t) => t.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Course? getCourse(String? courseId) {
    if (courseId == null) return null;
    try {
      return _courses.firstWhere((c) => c.id == courseId);
    } catch (_) {
      return null;
    }
  }
}
